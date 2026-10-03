import { Router, RequestHandler } from 'express';
import { CartViewModel } from '../../viewmodels/cart.viewmodel.js';
import {
  upsertCartItemSchema,
  removeCartItemParamSchema,
} from '../../presentation/http/schemas/cart.schema.js';

export const cartRoutes = (
  requireAuth: RequestHandler,
  vm: CartViewModel
): Router => {
  const router = Router();
  router.use(requireAuth);

  router.get('/', async (req, res, next) => {
    try {
      const cart = await vm.getCart(req.user!.id);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  });

  router.put('/items', async (req, res, next) => {
    try {
      const body = upsertCartItemSchema.parse(req.body);
      const cart = await vm.updateItem(req.user!.id, body.variantId, body.quantity);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  });

  router.delete('/items/:variantId', async (req, res, next) => {
    try {
      const { variantId } = removeCartItemParamSchema.parse(req.params);
      const cart = await vm.removeItem(req.user!.id, variantId);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  });

  router.delete('/', async (req, res, next) => {
    try {
      const cart = await vm.clearCart(req.user!.id);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
