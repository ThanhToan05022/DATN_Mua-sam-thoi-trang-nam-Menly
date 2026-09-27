import { Router } from 'express';
import { CategoryViewModel } from '../../viewmodels/category.viewmodel.js';

export const categoryRoutes = (vm: CategoryViewModel): Router => {
  const router = Router();

  router.get('/', async (_req, res, next) => {
    try {
      res.set('Cache-Control', 'public, max-age=300');
      const categories = await vm.getCategories();
      res.json(categories);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
