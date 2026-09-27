import { Router } from 'express';
import { ListProducts } from '../../../application/use-cases/product/list-products.js';
import { GetProduct } from '../../../application/use-cases/product/get-product.js';
import {
  listProductsSchema,
  productIdParamSchema,
} from '../schemas/product.schema.js';

export const productRoutes = (uc: {
  list: ListProducts;
  get: GetProduct;
}): Router => {
  const router = Router();

  router.get('/', async (req, res, next) => {
    try {
      res.set('Cache-Control', 'public, max-age=30');
      const query = listProductsSchema.parse(req.query);
      const page = await uc.list.execute(query);
      res.json(page);
    } catch (err) {
      next(err);
    }
  });

  router.get('/:id', async (req, res, next) => {
    try {
      const { id } = productIdParamSchema.parse(req.params);
      const product = await uc.get.execute(id);
      res.json(product);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
