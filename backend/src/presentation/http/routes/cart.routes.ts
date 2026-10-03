import { Router, RequestHandler } from 'express';
import { GetCart } from '../../../application/use-cases/cart/get-cart.js';
import { UpsertCartItem } from '../../../application/use-cases/cart/upsert-cart-item.js';
import { RemoveCartItem } from '../../../application/use-cases/cart/remove-cart-item.js';
import {
  upsertCartItemSchema,
  removeCartItemParamSchema,
} from '../schemas/cart.schema.js';

export const cartRoutes = (
  requireAuth: RequestHandler,
  uc: {
    get: GetCart;
    upsert: UpsertCartItem;
    remove: RemoveCartItem;
  }
): Router => {
  const router = Router();
  router.use(requireAuth);

  router.get('/', async (req, res, next) => {
    try {
      const cart = await uc.get.execute(req.user!.id);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  });

  router.put('/items', async (req, res, next) => {
    try {
      const body = upsertCartItemSchema.parse(req.body);
      await uc.upsert.execute({
        userId: req.user!.id,
        variantId: body.variantId,
        quantity: body.quantity,
      });
      const updatedCart = await uc.get.execute(req.user!.id);
      res.json(updatedCart);
    } catch (err) {
      next(err);
    }
  });

  router.delete('/items/:variantId', async (req, res, next) => {
    try {
      const { variantId } = removeCartItemParamSchema.parse(req.params);
      await uc.remove.execute(req.user!.id, variantId);
      const updatedCart = await uc.get.execute(req.user!.id);
      res.json(updatedCart);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
