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
import { createProductSchema, listProductsSchema, productIdParamSchema } from '../../presentation/http/schemas/product.schema.js';

export const adminRoutes = (
  requireAuth: RequestHandler,
  requireAdmin: RequestHandler,
  adminVm: AdminViewModel,
  productVm: ProductViewModel,
  requireStaffOrAdmin: RequestHandler = requireAdmin,
  reviewVm?: ReviewViewModel
): Router => {
  const router = Router();
  router.use(requireAuth);

  // Vận hành (Staff & Admin): Danh sách sản phẩm (kể cả chưa kích hoạt)
  router.get('/products', requireStaffOrAdmin, async (req, res, next) => {
    try {
      const query = listProductsSchema.parse(req.query);
      const page = await productVm.listProducts({ ...query, includeInactive: true });
      res.json(page);
    } catch (err) {
      next(err);
    }
  });

  // Nhân viên và Admin tạo sản phẩm cùng biến thể và danh sách URL ảnh.
  router.post('/products', requireStaffOrAdmin, async (req, res, next) => {
    try {
      const body = createProductSchema.parse(req.body);
      const product = await productVm.createProduct(body);
      res.status(201).json(product);
    } catch (err) {
      next(err);
    }
  });

  // Vận hành (Staff & Admin): Cập nhật sản phẩm
  router.put('/products/:id', requireStaffOrAdmin, async (req, res, next) => {
    try {
      const { id } = productIdParamSchema.parse(req.params);
      const updated = await productVm.updateProduct(id, req.body);
      res.json(updated);
    } catch (err) {
      next(err);
    }
  });

  // Vận hành (Staff & Admin): Điều chỉnh tồn kho thực tế
  router.post('/inventory/adjust', requireStaffOrAdmin, async (req, res, next) => {
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

  // Vận hành (Staff & Admin): Xem nhật ký biến động kho
  router.get('/inventory/movements', requireStaffOrAdmin, async (req, res, next) => {
    try {
      const variantId = req.query.variantId as string | undefined;
      const limit = Number(req.query.limit) || 50;
      const list = await adminVm.listMovements(variantId, limit);
      res.json(list);
    } catch (err) {
      next(err);
    }
  });

  // Vận hành (Staff & Admin): Quản lý & xem danh sách đơn hàng
  router.get('/orders', requireStaffOrAdmin, async (req, res, next) => {
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

  // Vận hành (Staff & Admin): Cập nhật trạng thái đơn hàng (xác nhận, giao hàng, hoàn tất, hủy)
  router.put('/orders/:id/status', requireStaffOrAdmin, async (req, res, next) => {
    try {
      const body = updateOrderStatusSchema.parse(req.body);
      await adminVm.updateOrderStatus(req.params.id, body.status, body.note, req.user!.id);
      res.json({ message: 'Cập nhật trạng thái thành công' });
    } catch (err) {
      next(err);
    }
  });

  // Quyền tối cao (Chỉ Admin): Xem nhật ký kiểm toán hệ thống
  router.get('/audit-log', requireAdmin, async (req, res, next) => {
    try {
      const limit = Number(req.query.limit) || 50;
      const logs = await adminVm.listAudit(limit);
      res.json(logs);
    } catch (err) {
      next(err);
    }
  });

  // Quyền tối cao (Chỉ Admin): Phân quyền vai trò người dùng
  router.put('/users/:id/role', requireAdmin, async (req, res, next) => {
    try {
      const body = setUserRoleSchema.parse(req.body);
      await adminVm.setUserRole(req.params.id, body.role);
      res.json({ message: 'Gán vai trò thành công' });
    } catch (err) {
      next(err);
    }
  });

  // Reviews management (Staff & Admin có thể xem, Admin có thể xóa)
  router.get('/reviews', requireStaffOrAdmin, async (req, res, next) => {
    try {
      if (!reviewVm) {
        res.json({ items: [], pageInfo: { limit: 20, hasNext: false, nextCursor: null } });
        return;
      }
      const limit = Number(req.query.limit) || 20;
      const page = Number(req.query.page) || 1;
      const result = await reviewVm.getAdminReviews(limit, page);
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  router.delete('/reviews/:id', requireAdmin, async (req, res, next) => {
    try {
      if (!reviewVm) {
        res.json({ message: 'Đã xóa đánh giá vi phạm' });
        return;
      }
      await reviewVm.adminDeleteReview(req.params.id, req.user!.id);
      res.json({ message: 'Đã xóa đánh giá vi phạm' });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
