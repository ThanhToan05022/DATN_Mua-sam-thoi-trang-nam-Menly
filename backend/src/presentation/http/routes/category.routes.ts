import { Router } from 'express';
import { ListCategories } from '../../../application/use-cases/product/list-categories.js';

export const categoryRoutes = (uc: { list: ListCategories }): Router => {
  const router = Router();

  router.get('/', async (_req, res, next) => {
    try {
      res.set('Cache-Control', 'public, max-age=300');
      const categories = await uc.list.execute();
      res.json(categories);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
