import { Router, RequestHandler } from 'express';
import { CreateOrder } from '../../../application/use-cases/order/create-order.js';
import { GetOrder } from '../../../application/use-cases/order/get-order.js';
import { ListMyOrders } from '../../../application/use-cases/order/list-my-orders.js';
import { TrackOrder } from '../../../application/use-cases/order/track-order.js';
import {
  createOrderSchema,
  trackOrderSchema,
  listOrdersQuerySchema,
} from '../schemas/order.schema.js';

export const orderRoutes = (
  requireAuth: RequestHandler,
  rateLimits: {
    order: RequestHandler;
    track: RequestHandler;
  },
  uc: {
    create: CreateOrder;
    get: GetOrder;
    listMy: ListMyOrders;
    track: TrackOrder;
  }
): Router => {
  const router = Router();

  // Public order tracking (guest lookup by code and phone)
  router.get('/track', rateLimits.track, async (req, res, next) => {
    try {
      const { code, phone } = trackOrderSchema.parse(req.query);
      const result = await uc.track.execute(code, phone);
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  // Authenticated routes
  router.post('/', requireAuth, rateLimits.order, async (req, res, next) => {
    try {
      const body = createOrderSchema.parse(req.body);
      const idempotencyKey = req.headers['idempotency-key'] as string | undefined;
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;

      const order = await uc.create.execute({
        userId: headerUserId || req.user!.id,
        userEmail: req.user?.email || headerEmail,
        addressId: body.addressId,
        ship: body.ship,
        paymentMethod: body.paymentMethod,
        items: body.items,
        idempotencyKey,
        note: body.note,
        voucherCode: body.voucherCode,
        discountAmount: body.discountAmount,
      });

      res.status(201).json(order);
    } catch (err) {
      next(err);
    }
  });

  router.get('/', requireAuth, async (req, res, next) => {
    try {
      const query = listOrdersQuerySchema.parse(req.query);
      const orders = await uc.listMy.execute({
        userId: req.user!.id,
        limit: query.limit,
        cursor: query.cursor,
      });
      res.json(orders);
    } catch (err) {
      next(err);
    }
  });

  router.get('/:id', requireAuth, async (req, res, next) => {
    try {
      const order = await uc.get.execute(
        req.params.id,
        req.user!.id,
        req.user!.role === 'admin'
      );
      res.json(order);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
