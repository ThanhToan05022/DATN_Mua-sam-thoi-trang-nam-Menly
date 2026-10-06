import { Router, RequestHandler } from 'express';
import { OrderViewModel } from '../../viewmodels/order.viewmodel.js';
import {
  createOrderSchema,
  trackOrderSchema,
  listOrdersQuerySchema,
} from '../../presentation/http/schemas/order.schema.js';

export const orderRoutes = (
  requireAuth: RequestHandler,
  rateLimits: {
    order: RequestHandler;
    track: RequestHandler;
  },
  vm: OrderViewModel,
  requireCustomer?: RequestHandler
): Router => {
  const router = Router();
  const mustBeCustomer: RequestHandler[] = requireCustomer ? [requireCustomer] : [];

  // Public order tracking (guest lookup by code and phone)
  router.get('/track', rateLimits.track, async (req, res, next) => {
    try {
      const { code, phone } = trackOrderSchema.parse(req.query);
      const result = await vm.trackOrder(code, phone);
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  // Authenticated routes
  // requireCustomer: guest (anonymous) không được tạo đơn, phải đăng nhập thật
  router.post('/', requireAuth, ...mustBeCustomer, rateLimits.order, async (req, res, next) => {
    try {
      const body = createOrderSchema.parse(req.body);
      const idempotencyKey = req.headers['idempotency-key'] as string | undefined;

      const order = await vm.createOrder({
        userId: req.user!.id,
        ship: body.ship,
        paymentMethod: body.paymentMethod,
        items: body.items,
        idempotencyKey,
      });

      res.status(201).json(order);
    } catch (err) {
      next(err);
    }
  });

  router.get('/', requireAuth, async (req, res, next) => {
    try {
      const query = listOrdersQuerySchema.parse(req.query);
      const orders = await vm.listMyOrders(req.user!.id, query.limit, query.cursor);
      res.json(orders);
    } catch (err) {
      next(err);
    }
  });

  router.get('/:id', requireAuth, async (req, res, next) => {
    try {
      const order = await vm.getOrder(
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
