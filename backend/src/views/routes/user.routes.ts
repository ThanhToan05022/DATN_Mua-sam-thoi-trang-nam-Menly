import { Router, RequestHandler } from 'express';
import { UserViewModel } from '../../viewmodels/user.viewmodel.js';

export const userRoutes = (
  requireAuth: RequestHandler,
  requireAdmin: RequestHandler,
  userVm: UserViewModel
): Router => {
  const router = Router();
  router.use(requireAuth, requireAdmin);

  router.get('/', async (req, res, next) => {
    try {
      const users = await userVm.listUsers();
      res.json(users);
    } catch (err) {
      next(err);
    }
  });

  router.post('/', async (req, res, next) => {
    try {
      const user = await userVm.createUser(req.body);
      res.status(201).json(user);
    } catch (err) {
      next(err);
    }
  });

  router.put('/:id', async (req, res, next) => {
    try {
      const user = await userVm.updateUser(req.params.id, req.body);
      res.json(user);
    } catch (err) {
      next(err);
    }
  });

  router.delete('/:id', async (req, res, next) => {
    try {
      const result = await userVm.deleteUser(req.params.id);
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  router.patch('/:id/lock', async (req, res, next) => {
    try {
      const isLocked = Boolean(req.body.isLocked);
      const user = await userVm.toggleLockUser(req.params.id, isLocked);
      res.json({
        message: isLocked
          ? 'Đã khóa tài khoản thành công'
          : 'Đã mở khóa tài khoản thành công',
        user,
      });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
