import { IAuthModel, AuthSession } from '../models/auth.model.js';
import { AppError } from '../models/types.js';

export interface LockoutStatus {
  isLocked: boolean;
  failedAttempts: number;
  lockedUntil?: string;
  retryAfterSeconds: number;
  remainingInCycle: number;
}

export class AuthViewModel {
  constructor(private readonly authModel: IAuthModel) {}

  async login(email: string, pass: string): Promise<AuthSession> {
    const normalized = email.toLowerCase().trim();

    // 1. Check if currently locked
    const lockout = this.authModel.getLockout(normalized);
    if (lockout?.lockedUntil && lockout.lockedUntil > new Date()) {
      const remainingSeconds = Math.ceil(
        (lockout.lockedUntil.getTime() - Date.now()) / 1000
      );
      const minutes = Math.floor(remainingSeconds / 60);
      const seconds = remainingSeconds % 60;
      const timeStr = minutes > 0 ? `${minutes} phút ${seconds} giây` : `${seconds} giây`;

      throw new AppError(
        'ACCOUNT_LOCKED',
        423,
        `Tài khoản đang bị tạm khóa do nhập sai nhiều lần. Vui lòng thử lại sau ${timeStr}.`,
        {
          lockedUntil: lockout.lockedUntil.toISOString(),
          retryAfterSeconds: remainingSeconds,
        }
      );
    }

    // 2. Verify credentials
    const session = await this.authModel.verifyCredentials(normalized, pass);

    // 3. Handle incorrect credentials with progressive lockout ladder
    if (!session) {
      const failResult = this.authModel.recordFailure(normalized);

      if (failResult.isLocked) {
        throw new AppError(
          'ACCOUNT_LOCKED',
          423,
          `Bạn đã nhập sai mật khẩu ${failResult.record.failedAttempts} lần. Tài khoản bị tạm khóa trong ${failResult.lockoutMinutes} phút.`,
          {
            lockedUntil: failResult.record.lockedUntil?.toISOString(),
            retryAfterSeconds: failResult.retryAfterSeconds,
            lockoutMinutes: failResult.lockoutMinutes,
            failedAttempts: failResult.record.failedAttempts,
          }
        );
      }

      throw new AppError(
        'INVALID_CREDENTIALS',
        401,
        `Email hoặc mật khẩu không chính xác. Bạn còn ${failResult.remainingInCycle} lần thử trước khi bị khóa ${failResult.lockoutMinutes} phút.`,
        {
          failedAttempts: failResult.record.failedAttempts,
          remainingAttempts: failResult.remainingInCycle,
          nextLockoutMinutes: failResult.lockoutMinutes,
        }
      );
    }

    // 4. Successful login -> reset failed attempts and lockout state
    this.authModel.resetLockout(normalized);

    return session;
  }

  getStatus(email: string): LockoutStatus {
    const normalized = email.toLowerCase().trim();
    const lockout = this.authModel.getLockout(normalized);

    if (lockout?.lockedUntil && lockout.lockedUntil > new Date()) {
      const remainingSeconds = Math.ceil(
        (lockout.lockedUntil.getTime() - Date.now()) / 1000
      );
      return {
        isLocked: true,
        failedAttempts: lockout.failedAttempts,
        lockedUntil: lockout.lockedUntil.toISOString(),
        retryAfterSeconds: remainingSeconds,
        remainingInCycle: 0,
      };
    }

    const failed = lockout?.failedAttempts || 0;
    const remaining = 5 - (failed % 5);

    return {
      isLocked: false,
      failedAttempts: failed,
      retryAfterSeconds: 0,
      remainingInCycle: remaining === 0 ? 5 : remaining,
    };
  }

  unlock(email: string): void {
    const normalized = email.toLowerCase().trim();
    this.authModel.resetLockout(normalized);
  }

  async register(
    name: string,
    email: string,
    pass: string,
    role?: 'admin' | 'user'
  ): Promise<AuthSession> {
    const normalized = email.toLowerCase().trim();
    return this.authModel.register(name, normalized, pass, role);
  }
}
