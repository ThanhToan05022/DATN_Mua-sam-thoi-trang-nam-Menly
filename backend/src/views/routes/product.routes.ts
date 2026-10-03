import { Router } from 'express';
import { ProductViewModel } from '../../viewmodels/product.viewmodel.js';
import {
  listProductsSchema,
  productIdParamSchema,
} from '../../presentation/http/schemas/product.schema.js';

export const productRoutes = (vm: ProductViewModel): Router => {
  const router = Router();

  router.get('/', async (req, res, next) => {
    try {
      res.set('Cache-Control', 'public, max-age=30');
      const query = listProductsSchema.parse(req.query);
      const page = await vm.listProducts(query);
      res.json(page);
    } catch (err) {
      next(err);
    }
  });

  router.get('/:id', async (req, res, next) => {
    try {
      const { id } = productIdParamSchema.parse(req.params);
      const product = await vm.getProductDetail(id);
      res.json(product);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
