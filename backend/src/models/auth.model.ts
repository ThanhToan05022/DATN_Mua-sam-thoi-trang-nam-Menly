import { SupabaseClient } from '@supabase/supabase-js';
import { IUserModel } from './user.model.js';
import { AppError } from './types.js';

export const PROGRESSIVE_LOCKOUT_MINUTES = [5, 10, 20, 30, 60] as const;

export interface LockoutRecord {
  failedAttempts: number;
  lockoutTier: number;
  lockedUntil?: Date;
  lastFailedAt: Date;
}

export interface FailedAttemptResult {
  record: LockoutRecord;
  isLocked: boolean;
  lockoutMinutes: number;
  remainingInCycle: number;
  retryAfterSeconds: number;
}

export interface AuthSession {
  user: {
    id: string;
    email: string;
    name?: string;
    role: 'customer' | 'admin' | 'staff';
  };
  accessToken: string;
}

export interface IAuthModel {
  getLockout(identifier: string): LockoutRecord | null;
  recordFailure(identifier: string): FailedAttemptResult;
  resetLockout(identifier: string): void;
  verifyCredentials(email: string, pass: string): Promise<AuthSession | null>;
  register(name: string, email: string, pass: string, role?: 'admin' | 'staff' | 'user'): Promise<AuthSession>;
}

export class AuthModel implements IAuthModel {
  private lockoutStore = new Map<string, LockoutRecord>();

  constructor(
    private readonly supabase?: SupabaseClient,
    private readonly userModel?: IUserModel
  ) {}

  getLockout(identifier: string): LockoutRecord | null {
    const key = identifier.toLowerCase().trim();
    const record = this.lockoutStore.get(key);
    if (!record) return null;

    if (record.lockedUntil && record.lockedUntil <= new Date()) {
      record.lockedUntil = undefined;
    }

    return record;
  }

  recordFailure(identifier: string): FailedAttemptResult {
    const key = identifier.toLowerCase().trim();
    const now = new Date();
    const existing = this.getLockout(key);

    let attempts = (existing?.failedAttempts || 0) + 1;
    let isLocked = false;
    let lockoutMinutes = 0;
    let retryAfterSeconds = 0;

    if (attempts % 5 === 0) {
      const tierIndex = Math.min(
        Math.floor(attempts / 5) - 1,
        PROGRESSIVE_LOCKOUT_MINUTES.length - 1
      );
      lockoutMinutes = PROGRESSIVE_LOCKOUT_MINUTES[tierIndex];
      const lockedUntil = new Date(now.getTime() + lockoutMinutes * 60 * 1000);
      retryAfterSeconds = lockoutMinutes * 60;
      isLocked = true;

      const record: LockoutRecord = {
        failedAttempts: attempts,
        lockoutTier: tierIndex,
        lockedUntil,
        lastFailedAt: now,
      };
      this.lockoutStore.set(key, record);

      return {
        record,
        isLocked,
        lockoutMinutes,
        remainingInCycle: 0,
        retryAfterSeconds,
      };
    }

    const currentTier = existing?.lockoutTier || 0;
    const remainingInCycle = 5 - (attempts % 5);
    const nextTierIndex = Math.min(
      Math.floor(attempts / 5),
      PROGRESSIVE_LOCKOUT_MINUTES.length - 1
    );
    lockoutMinutes = PROGRESSIVE_LOCKOUT_MINUTES[nextTierIndex];

    const record: LockoutRecord = {
      failedAttempts: attempts,
      lockoutTier: currentTier,
      lastFailedAt: now,
    };
    this.lockoutStore.set(key, record);

    return {
      record,
      isLocked: false,
      lockoutMinutes,
      remainingInCycle,
      retryAfterSeconds: 0,
    };
  }

  resetLockout(identifier: string): void {
    const key = identifier.toLowerCase().trim();
    this.lockoutStore.delete(key);
  }

  async register(name: string, email: string, pass: string, role?: 'admin' | 'staff' | 'user'): Promise<AuthSession> {
    const normalized = email.toLowerCase().trim();
    if (this.userModel) {
      const user = await this.userModel.createUser({
        name,
        email: normalized,
        password: pass,
        role: role === 'staff' ? 'staff' : (role === 'admin' ? 'admin' : 'user'),
      });

      const userRole = user.role === 'admin' ? 'admin' : user.role === 'staff' ? 'staff' : 'customer';

      return {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: userRole,
        },
        accessToken:
          user.role === 'admin'
            ? `mock-admin-token-${user.id}`
            : user.role === 'staff'
            ? `mock-staff-token-${user.id}`
            : `mock-user-token-${user.id}`,
      };
    }

    const assignedRole = role === 'admin' ? 'admin' : role === 'staff' ? 'staff' : 'customer';
    return {
      user: { id: `usr-${Date.now()}`, email: normalized, name, role: assignedRole },
      accessToken:
        assignedRole === 'admin'
          ? `mock-admin-token-${Date.now()}`
          : assignedRole === 'staff'
          ? `mock-staff-token-${Date.now()}`
          : `mock-user-token-${Date.now()}`,
    };
  }

  async verifyCredentials(email: string, pass: string): Promise<AuthSession | null> {
    const normalized = email.toLowerCase().trim();

    // Check with UserModel first if available
    if (this.userModel) {
      const user = await this.userModel.getUserByEmail(normalized);
      if (user) {
        if (user.isLocked) {
          throw new AppError(
            'ACCOUNT_LOCKED',
            403,
            'Tài khoản của bạn đã bị khoá. Vui lòng liên hệ quản trị viên.'
          );
        }

        if (user.password === pass) {
          const userRole = user.role === 'admin' ? 'admin' : user.role === 'staff' ? 'staff' : 'customer';
          return {
            user: {
              id: user.id,
              email: user.email,
              name: user.name,
              role: userRole,
            },
            accessToken:
              user.role === 'admin'
                ? `mock-admin-token-${user.id}`
                : user.role === 'staff'
                ? `mock-staff-token-${user.id}`
                : `mock-user-token-${user.id}`,
          };
        }
      }
    }

    if (this.supabase) {
      try {
        const { data, error } = await this.supabase.auth.signInWithPassword({
          email: normalized,
          password: pass,
        });

        if (!error && data?.user && data?.session) {
          const { data: profile } = await this.supabase
            .from('profiles')
            .select('role')
            .eq('id', data.user.id)
            .single();

          const profileRole = profile?.role === 'admin' ? 'admin' : profile?.role === 'staff' ? 'staff' : 'customer';

          return {
            user: {
              id: data.user.id,
              email: data.user.email || normalized,
              name: data.user.user_metadata?.full_name || 'Người dùng',
              role: profileRole,
            },
            accessToken: data.session.access_token,
          };
        }
      } catch {
        // Fall through to mock credentials
      }
    }

    // Mock credentials fallback
    if (normalized === 'admin@gmail.com' && (pass === '123456' || pass === 'Admin@123456')) {
      return {
        user: { id: 'usr-admin-001', email: normalized, name: 'Admin MenShop', role: 'admin' },
        accessToken: 'mock-admin-token-xyz',
      };
    }

    if (normalized === 'admin@menshop.vn' && (pass === 'Admin@123456' || pass === '123456')) {
      return {
        user: { id: 'mock-admin-uuid', email: normalized, name: 'Admin MenShop', role: 'admin' },
        accessToken: 'mock-admin-token-xyz',
      };
    }

    if (normalized === 'staff@gmail.com' && (pass === '123456' || pass === 'Staff@123456')) {
      return {
        user: { id: 'usr-staff-001', email: normalized, name: 'Nhân Viên MenShop', role: 'staff' },
        accessToken: 'mock-staff-token-xyz',
      };
    }

    if (
      (normalized === 'customer@menshop.vn' || normalized === 'customer@gmail.com') &&
      (pass === 'Customer@123' || pass === 'customer@123' || pass === '123456')
    ) {
      return {
        user: { id: 'mock-user-uuid', email: normalized, role: 'customer' },
        accessToken: 'mock-user-token-xyz',
      };
    }

    return null;
  }
}
