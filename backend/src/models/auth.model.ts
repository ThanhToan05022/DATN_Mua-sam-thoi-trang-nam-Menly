import { SupabaseClient, createClient } from '@supabase/supabase-js';
import { IUserModel } from './user.model.js';
import { AppError } from './types.js';
import { env } from '../config/env.js';

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
  sendPasswordResetEmail(email: string): Promise<void>;
}

export class AuthModel implements IAuthModel {
  private lockoutStore = new Map<string, LockoutRecord>();
  private anonClient?: SupabaseClient;

  constructor(
    private readonly supabase?: SupabaseClient,
    private readonly userModel?: IUserModel
  ) {
    if (env.SUPABASE_URL && env.SUPABASE_ANON_KEY) {
      try {
        this.anonClient = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
          auth: { persistSession: false, autoRefreshToken: false },
        });
      } catch (_) {}
    }
  }

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
    const assignedRole = role === 'admin' ? 'admin' : role === 'staff' ? 'staff' : 'customer';

    if (this.supabase) {
      const dbRole = assignedRole === 'admin' ? 'admin' : (assignedRole === 'staff' ? 'staff' : 'customer');
      let authUserId: string | null = null;
      let sessionToken: string | null = null;

      try {
        const { data: createData, error: createError } = await this.supabase.auth.admin.createUser({
          email: normalized,
          password: pass,
          email_confirm: true,
          user_metadata: { full_name: name.trim(), role: dbRole },
        });

        if (createError) {
          if (
            createError.message.toLowerCase().includes('already') ||
            createError.message.toLowerCase().includes('registered')
          ) {
            throw new AppError('EMAIL_EXISTS', 400, 'Email này đã được sử dụng');
          }
          console.warn('auth.admin.createUser error, falling back:', createError.message);
        }

        if (createData?.user) {
          authUserId = createData.user.id;
        }
      } catch (e) {
        if (e instanceof AppError) throw e;
        console.warn('auth.admin.createUser exception:', e);
      }

      const finalId = authUserId || crypto.randomUUID();

      await this.supabase.from('profiles').upsert({
        id: finalId,
        email: normalized,
        full_name: name.trim(),
        role: dbRole,
        is_locked: false,
      });

      // Try generating a clean session token via anonClient without touching this.supabase
      if (this.anonClient) {
        try {
          const { data: signInData } = await this.anonClient.auth.signInWithPassword({
            email: normalized,
            password: pass,
          });
          if (signInData?.session?.access_token) {
            sessionToken = signInData.session.access_token;
          }
        } catch (_) {}
      }

      return {
        user: {
          id: finalId,
          email: normalized,
          name: name.trim(),
          role: assignedRole,
        },
        accessToken: sessionToken || `supabase-session-${finalId}`,
      };
    }

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

    // 1. Prioritize real Supabase Authentication
    if (this.supabase) {
      try {
        let authEmail = normalized;
        if (normalized === 'admin@gmail.com') authEmail = 'admin@menshop.vn';
        if (normalized === 'staff@gmail.com') authEmail = 'staff@menshop.vn';
        const clientForAuth = this.anonClient || this.supabase;
        const { data, error } = await clientForAuth.auth.signInWithPassword({
          email: authEmail,
          password: pass,
        });

        if (!error && data?.user && data?.session) {
          const { data: profile } = await this.supabase
            .from('profiles')
            .select('role, is_locked, full_name')
            .eq('id', data.user.id)
            .maybeSingle();

          if (profile?.is_locked) {
            throw new AppError(
              'ACCOUNT_LOCKED',
              403,
              'Tài khoản của bạn đã bị khoá. Vui lòng liên hệ quản trị viên.'
            );
          }

          const rawRole = profile?.role || (data.user.user_metadata?.role as string) || 'customer';
          const profileRole = rawRole === 'admin' ? 'admin' : rawRole === 'staff' ? 'staff' : 'customer';

          return {
            user: {
              id: data.user.id,
              email: normalized,
              name: profile?.full_name || (data.user.user_metadata?.full_name as string) || 'Người dùng',
              role: profileRole,
            },
            accessToken: data.session.access_token,
          };
        }
      } catch (err) {
        if (err instanceof AppError && err.code === 'ACCOUNT_LOCKED') throw err;
      }
    }

    // 2. Check with UserModel only when using the in-memory development database.
    if (!this.supabase && this.userModel) {
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

    // A configured Supabase instance must authenticate against Supabase and return its JWT.
    // Do not issue mock tokens for a real database connection.
    if (this.supabase) return null;

    // 3. Fallback credentials for testing or offline dev
    if (normalized === 'admin@gmail.com' && (pass === '123456' || pass === 'Admin@123456')) {
      return {
        user: { id: '0f444d92-322c-4956-b452-0c5c10950508', email: normalized, name: 'Admin MenShop', role: 'admin' },
        accessToken: 'mock-admin-token-xyz',
      };
    }

    if (normalized === 'admin@menshop.vn' && (pass === 'Admin@123456' || pass === '123456')) {
      return {
        user: { id: '0f444d92-322c-4956-b452-0c5c10950508', email: normalized, name: 'Admin MenShop', role: 'admin' },
        accessToken: 'mock-admin-token-xyz',
      };
    }

    if (normalized === 'staff@gmail.com' && (pass === '123456' || pass === 'Staff@123456')) {
      return {
        user: { id: 'd604e122-aa50-47e0-ac44-10a2473af6ce', email: normalized, name: 'Nhân Viên MenShop', role: 'staff' },
        accessToken: 'mock-staff-token-xyz',
      };
    }

    if (
      (normalized === 'customer@menshop.vn' || normalized === 'customer@gmail.com') &&
      (pass === 'Customer@123' || pass === 'customer@123' || pass === 'Customer@123456' || pass === '123456')
    ) {
      return {
        user: { id: '7fb74d58-4155-4ab5-8124-cb0b5bb6651d', email: normalized, role: 'customer' },
        accessToken: 'mock-user-token-xyz',
      };
    }

    return null;
  }

  async sendPasswordResetEmail(email: string): Promise<void> {
    const normalized = email.toLowerCase().trim();
    if (this.supabase) {
      const { error } = await this.supabase.auth.resetPasswordForEmail(normalized, {
        redirectTo: 'http://localhost:5000/api/v1/auth/reset-password-callback',
      });
      if (error) {
        throw new AppError('RESET_PASSWORD_FAILED', 500, error.message);
      }
    } else {
      // Mock logic for in-memory
      console.log(`[Mock] Send password reset email to ${normalized}`);
    }
  }
}
