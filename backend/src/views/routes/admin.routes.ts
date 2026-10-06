import { Router, RequestHandler } from 'express';
import { AdminViewModel } from '../../viewmodels/admin.viewmodel.js';
import { ProductViewModel } from '../../viewmodels/product.viewmodel.js';
import { ReviewViewModel } from '../../viewmodels/review.viewmodel.js';
import {
  adjustStockSchema,
  updateOrderStatusSchema,
  setUserRoleSchema,
  adminOrdersQuerySchema,
} from '../../presentation/http/schemas/admin.schema.js';
import { listProductsSchema } from '../../presentation/http/schemas/product.schema.js';

export const adminRoutes = (
  requireAuth: RequestHandler,
  requireAdmin: RequestHandler,
  adminVm: AdminViewModel,
  productVm: ProductViewModel,
  reviewVm: ReviewViewModel
): Router => {
  const router = Router();
  router.use(requireAuth, requireAdmin);

  // Products (including inactive)
  router.get('/products', async (req, res, next) => {
    try {
      const query = listProductsSchema.parse(req.query);
      const page = await productVm.listProducts({ ...query, includeInactive: true });
      res.json(page);
    } catch (err) {
      next(err);
    }
  });

  // Inventory adjustment
  router.post('/inventory/adjust', async (req, res, next) => {
    try {
      const body = adjustStockSchema.parse(req.body);
      const result = await adminVm.adjustStock(
        body.variantId,
        body.delta,
        body.reason,
        body.note,
        req.user!.id
      );
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  router.get('/inventory/movements', async (req, res, next) => {
    try {
      const variantId = req.query.variantId as string | undefined;
      const limit = Number(req.query.limit) || 50;
      const list = await adminVm.listMovements(variantId, limit);
      res.json(list);
    } catch (err) {
      next(err);
    }
  });

  // Orders management
  router.get('/orders', async (req, res, next) => {
    try {
      const query = adminOrdersQuerySchema.parse(req.query);
      const orders = await adminVm.listOrders(
        query.limit,
        query.status,
        query.cursor,
        query.fromDate,
        query.toDate,
        query.day
      );
      res.json(orders);
    } catch (err) {
      next(err);
    }
  });

  router.put('/orders/:id/status', async (req, res, next) => {
    try {
      const body = updateOrderStatusSchema.parse(req.body);
      await adminVm.updateOrderStatus(req.params.id, body.status, body.note, req.user!.id);
      res.json({ message: 'Cập nhật trạng thái thành công' });
    } catch (err) {
      next(err);
    }
  });

  // Audit Logs & Roles
  router.get('/audit-log', async (req, res, next) => {
    try {
      const limit = Number(req.query.limit) || 50;
      const logs = await adminVm.listAudit(limit);
      res.json(logs);
    } catch (err) {
      next(err);
    }
  });

  router.put('/users/:id/role', async (req, res, next) => {
    try {
      const body = setUserRoleSchema.parse(req.body);
      await adminVm.setUserRole(req.params.id, body.role);
      res.json({ message: 'Gán vai trò thành công' });
    } catch (err) {
      next(err);
    }
  });

  // Reviews management
  router.get('/reviews', async (req, res, next) => {
    try {
      const limit = Number(req.query.limit) || 20;
      const page = Number(req.query.page) || 1;
      const result = await reviewVm.getAdminReviews(limit, page);
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  router.delete('/reviews/:id', async (req, res, next) => {
    try {
      await reviewVm.adminDeleteReview(req.params.id, req.user!.id);
      res.json({ message: 'Đã xóa đánh giá vi phạm' });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
