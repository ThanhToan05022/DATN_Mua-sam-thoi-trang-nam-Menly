import { Router, RequestHandler } from 'express';
import { AuthViewModel } from '../../viewmodels/auth.viewmodel.js';
import { loginSchema, registerSchema, unlockSchema, forgotPasswordSchema } from '../../presentation/http/schemas/auth.schema.js';
import { AppError } from '../../models/types.js';
import { IUserModel } from '../../models/user.model.js';

export const authRoutes = (
  authVm: AuthViewModel,
  requireAuth?: RequestHandler,
  requireAdmin?: RequestHandler,
  userModel?: IUserModel
): Router => {
  const router = Router();

  // 1. Register new user (regular customer or staff)
  router.post('/register', async (req, res, next) => {
    try {
      const body = registerSchema.parse(req.body);
      const targetRole = body.role === 'staff' ? 'staff' : (body.role === 'admin' ? 'admin' : 'user');
      const userName = body.name || body.fullName || 'Người dùng';
      const session = await authVm.register(userName, body.email, body.password, targetRole);
      res.status(201).json({
        message: targetRole === 'staff' ? 'Đăng ký tài khoản nhân viên thành công' : 'Đăng ký tài khoản thành công',
        user: session.user,
        accessToken: session.accessToken,
      });
    } catch (err) {
      next(err);
    }
  });

  // 2. Login with progressive lockout ladder (5-10-20-30-60 mins)
  router.post('/login', async (req, res, next) => {
    try {
      const body = loginSchema.parse(req.body);
      const session = await authVm.login(body.email, body.password);
      res.json({
        message: 'Đăng nhập thành công',
        user: session.user,
        accessToken: session.accessToken,
      });
    } catch (err: unknown) {
      if (err instanceof AppError && err.code === 'ACCOUNT_LOCKED') {
        const details = err.details as { retryAfterSeconds?: number } | undefined;
        if (details?.retryAfterSeconds) {
          res.setHeader('Retry-After', String(details.retryAfterSeconds));
        }
      }
      next(err);
    }
  });

  // 3. Check current account lockout status
  router.get('/status', (req, res, next) => {
    try {
      const email = String(req.query.email || '');
      if (!email) {
        throw new AppError('VALIDATION_ERROR', 400, 'Thiếu tham số email');
      }
      const status = authVm.getStatus(email);
      res.json(status);
    } catch (err) {
      next(err);
    }
  });

  // 4. Unlock account (admin or testing helper)
  const unlockMiddlewares = requireAuth && requireAdmin ? [requireAuth, requireAdmin] : [];
  router.post('/unlock', ...unlockMiddlewares, (req, res, next) => {
    try {
      const body = unlockSchema.parse(req.body);
      authVm.unlock(body.email);
      res.json({ message: `Đã mở khóa tài khoản ${body.email} thành công` });
    } catch (err) {
      next(err);
    }
  });

  // 5. Change password (both POST and PUT supported)
  const authMiddleware = requireAuth ? [requireAuth] : [];
  const changePasswordHandler: RequestHandler = async (req, res, next) => {
    try {
      const { currentPassword, newPassword } = req.body || {};
      if (!newPassword || typeof newPassword !== 'string' || newPassword.length < 6) {
        throw new AppError('VALIDATION_ERROR', 400, 'Mật khẩu mới phải có tối thiểu 6 ký tự');
      }

      const userEmail = req.user?.email || (req.headers['x-user-email'] as string) || '';
      const userId = req.user?.id || (req.headers['x-user-id'] as string) || '';

      if (userModel) {
        if (currentPassword) {
          const existing = (userEmail ? await userModel.getUserByEmail(userEmail) : null) ||
                           (userId ? await userModel.getUserById(userId) : null);
          if (existing?.password && existing.password !== currentPassword) {
            throw new AppError('INVALID_CREDENTIALS', 400, 'Mật khẩu hiện tại không chính xác');
          }
        }
        if (userId) await userModel.updatePassword(userId, newPassword);
        if (userEmail) await userModel.updatePassword(userEmail, newPassword);
      }

      res.json({ message: 'Đổi mật khẩu thành công' });
    } catch (err) {
      next(err);
    }
  };

  router.post('/change-password', ...authMiddleware, changePasswordHandler);
  router.put('/change-password', ...authMiddleware, changePasswordHandler);

  // 6. Forgot password
  router.post('/forgot-password', async (req, res, next) => {
    try {
      const body = forgotPasswordSchema.parse(req.body);
      await authVm.forgotPassword(body.email);
      res.json({ message: `Đã gửi email khôi phục mật khẩu đến ${body.email}` });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
