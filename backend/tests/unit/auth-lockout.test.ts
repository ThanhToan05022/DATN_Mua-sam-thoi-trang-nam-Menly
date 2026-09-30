import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AuthModel, PROGRESSIVE_LOCKOUT_MINUTES } from '../../src/models/auth.model.js';
import { AuthViewModel } from '../../src/viewmodels/auth.viewmodel.js';
import { AppError } from '../../src/models/types.js';

describe('AuthViewModel - Progressive Login Lockout Ladder (5-10-20-30-60 mins)', () => {
  let authModel: AuthModel;
  let authVm: AuthViewModel;
  const testEmail = 'user@example.com';

  beforeEach(() => {
    authModel = new AuthModel(undefined); // in-memory mock mode
    authVm = new AuthViewModel(authModel);
    vi.useRealTimers();
  });

  it('Tier progression definition: should have tiers [5, 10, 20, 30, 60] minutes', () => {
    expect(PROGRESSIVE_LOCKOUT_MINUTES).toEqual([5, 10, 20, 30, 60]);
  });

  it('Attempts 1 to 4: should reject with 401 and indicate remaining attempts without locking', async () => {
    for (let i = 1; i <= 4; i++) {
      try {
        await authVm.login(testEmail, 'wrong-password');
        expect.unreachable('Should have thrown AppError');
      } catch (err: unknown) {
        expect(err).toBeInstanceOf(AppError);
        const appErr = err as AppError<Record<string, any>>;
        expect(appErr.status).toBe(401);
        expect(appErr.code).toBe('INVALID_CREDENTIALS');
        expect(appErr.details?.remainingAttempts).toBe(5 - i);
        expect(appErr.details?.nextLockoutMinutes).toBe(5);
      }
    }

    const status = authVm.getStatus(testEmail);
    expect(status.isLocked).toBe(false);
    expect(status.failedAttempts).toBe(4);
    expect(status.remainingInCycle).toBe(1);
  });

  it('Attempt 5: should trigger Tier 1 lockout (5 minutes) and return 423 ACCOUNT_LOCKED', async () => {
    // 4 failed attempts
    for (let i = 0; i < 4; i++) {
      await authVm.login(testEmail, 'wrong').catch(() => {});
    }

    // 5th attempt
    try {
      await authVm.login(testEmail, 'wrong');
      expect.unreachable('Should have thrown ACCOUNT_LOCKED');
    } catch (err: unknown) {
      expect(err).toBeInstanceOf(AppError);
      const appErr = err as AppError<Record<string, any>>;
      expect(appErr.status).toBe(423);
      expect(appErr.code).toBe('ACCOUNT_LOCKED');
      expect(appErr.details?.lockoutMinutes).toBe(5);
      expect(appErr.details?.retryAfterSeconds).toBe(300);
      expect(appErr.message).toContain('5 phút');
    }

    const status = authVm.getStatus(testEmail);
    expect(status.isLocked).toBe(true);
    expect(status.failedAttempts).toBe(5);
    expect(status.retryAfterSeconds).toBeGreaterThan(0);
  });

  it('Immediate retry while locked: should be rejected immediately without verifying password', async () => {
    // Fail 5 times to lock
    for (let i = 0; i < 5; i++) {
      await authVm.login(testEmail, 'wrong').catch(() => {});
    }

    // Attempt even with correct credentials while locked
    try {
      await authVm.login(testEmail, 'Customer@123');
      expect.unreachable('Should have rejected because account is locked');
    } catch (err: unknown) {
      const appErr = err as AppError;
      expect(appErr.status).toBe(423);
      expect(appErr.code).toBe('ACCOUNT_LOCKED');
      expect(appErr.message).toContain('đang bị tạm khóa');
    }
  });

  it('Progression: 10 fails -> 10m, 15 fails -> 20m, 20 fails -> 30m, 25 fails -> 60m', () => {
    const expectedTiers = [
      { attempts: 5, expectedMinutes: 5 },
      { attempts: 10, expectedMinutes: 10 },
      { attempts: 15, expectedMinutes: 20 },
      { attempts: 20, expectedMinutes: 30 },
      { attempts: 25, expectedMinutes: 60 },
      { attempts: 30, expectedMinutes: 60 }, // caps at 60
    ];

    for (const { attempts, expectedMinutes } of expectedTiers) {
      // Simulate failed attempts up to target
      const mockKey = `user-${attempts}@example.com`;
      for (let i = 1; i < attempts; i++) {
        authModel.recordFailure(mockKey);
      }
      const result = authModel.recordFailure(mockKey);
      expect(result.isLocked).toBe(true);
      expect(result.record.failedAttempts).toBe(attempts);
      expect(result.lockoutMinutes).toBe(expectedMinutes);
      expect(result.retryAfterSeconds).toBe(expectedMinutes * 60);
    }
  });

  it('Successful login: should reset lockout status', async () => {
    // 3 failed attempts
    for (let i = 0; i < 3; i++) {
      await authVm.login('customer@menshop.vn', 'wrong').catch(() => {});
    }
    expect(authVm.getStatus('customer@menshop.vn').failedAttempts).toBe(3);

    // Correct password
    const session = await authVm.login('customer@menshop.vn', 'Customer@123');
    expect(session.user.email).toBe('customer@menshop.vn');

    // Lockout record must be completely cleared
    const statusAfter = authVm.getStatus('customer@menshop.vn');
    expect(statusAfter.failedAttempts).toBe(0);
    expect(statusAfter.isLocked).toBe(false);
  });
});

describe('loginSchema - Password Validation Rules', () => {
  it('should accept 8-character lowercase password without uppercase, numbers or special characters', async () => {
    const { loginSchema } = await import('../../src/presentation/http/schemas/auth.schema.js');
    const result = loginSchema.safeParse({
      email: 'user@example.com',
      password: 'abcdefgh', // 8 chars, lowercase only
    });
    expect(result.success).toBe(true);
  });

  it('should reject password under 6 characters', async () => {
    const { loginSchema } = await import('../../src/presentation/http/schemas/auth.schema.js');
    const result = loginSchema.safeParse({
      email: 'user@example.com',
      password: 'abcde', // 5 chars
    });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toContain('tối thiểu 6 ký tự');
    }
  });

  it('should accept password with numbers and symbols if 8+ chars (not mandatory)', async () => {
    const { loginSchema } = await import('../../src/presentation/http/schemas/auth.schema.js');
    const result = loginSchema.safeParse({
      email: 'Admin@MenShop.vn',
      password: 'Admin@123456',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.email).toBe('admin@menshop.vn'); // normalized lowercase
    }
  });
});

