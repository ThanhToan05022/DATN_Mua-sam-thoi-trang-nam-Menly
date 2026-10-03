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
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;

      const order = await vm.createOrder({
        // Ưu tiên id đã xác thực từ token; header do client gửi chỉ là fallback
        // để không vỡ luồng với app đang dùng id giả lập.
        userId: req.user!.id || headerUserId || '',
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
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const orders = await vm.listMyOrders(
        req.user!.id,
        query.limit,
        query.cursor,
        req.user?.email || headerEmail,
        headerUserId
      );
      res.json(orders);
    } catch (err) {
      next(err);
    }
  });

  router.put('/:id/cancel', requireAuth, async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const { note } = req.body || {};
      const order = await vm.cancelOrder(
        req.params.id,
        req.user!.id,
        note,
        req.user?.email || headerEmail,
        headerUserId
      );
      res.json(order);
    } catch (err) {
      next(err);
    }
  });

  router.get('/:id', requireAuth, async (req, res, next) => {
    try {
      const order = await vm.getOrder(
        req.params.id,
        req.user!.id,
        req.user!.role === 'admin',
        req.user?.email || (req.headers['x-user-email'] as string)
      );
      res.json(order);
    } catch (err) {
      next(err);
    }
  });

  return router;
};
