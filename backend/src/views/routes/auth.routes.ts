import { Router, RequestHandler } from 'express';
import { AuthViewModel } from '../../viewmodels/auth.viewmodel.js';
import { loginSchema, registerSchema, unlockSchema } from '../../presentation/http/schemas/auth.schema.js';
import { AppError } from '../../models/types.js';

export const authRoutes = (
  authVm: AuthViewModel,
  requireAuth?: RequestHandler,
  requireAdmin?: RequestHandler
): Router => {
  const router = Router();

  // 1. Register new user (strictly for regular users)
  router.post('/register', async (req, res, next) => {
    try {
      const body = registerSchema.parse(req.body);
      const session = await authVm.register(body.name, body.email, body.password, 'user');
      res.status(201).json({
        message: 'Đăng ký tài khoản thành công',
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

  return router;
};
