import { Router, RequestHandler } from 'express';
import { AdjustStock } from '../../../application/use-cases/admin/adjust-stock.js';
import { UpdateOrderStatus } from '../../../application/use-cases/admin/update-order-status.js';
import { ListAdminOrders } from '../../../application/use-cases/admin/list-admin-orders.js';
import { SetUserRole } from '../../../application/use-cases/admin/set-user-role.js';
import { ListInventoryMovements } from '../../../application/use-cases/admin/list-inventory-movements.js';
import { ListAuditLog } from '../../../application/use-cases/admin/list-audit-log.js';
import { ListProducts } from '../../../application/use-cases/product/list-products.js';
import {
  adjustStockSchema,
  updateOrderStatusSchema,
  setUserRoleSchema,
  adminOrdersQuerySchema,
} from '../schemas/admin.schema.js';
import { listProductsSchema } from '../schemas/product.schema.js';

export const adminRoutes = (
  requireAuth: RequestHandler,
  requireAdmin: RequestHandler,
  uc: {
    adjustStock: AdjustStock;
    updateStatus: UpdateOrderStatus;
    listOrders: ListAdminOrders;
    setUserRole: SetUserRole;
    listMovements: ListInventoryMovements;
    listAudit: ListAuditLog;
    listProducts: ListProducts;
  }
): Router => {
  const router = Router();
  router.use(requireAuth, requireAdmin);

  // Products
  router.get('/products', async (req, res, next) => {
    try {
      const query = listProductsSchema.parse(req.query);
      const page = await uc.listProducts.execute(query);
      res.json(page);
    } catch (err) {
      next(err);
    }
  });

  // Inventory
  router.post('/inventory/adjust', async (req, res, next) => {
    try {
      const body = adjustStockSchema.parse(req.body);
      const result = await uc.adjustStock.execute({
        variantId: body.variantId,
        delta: body.delta,
        reason: body.reason,
        note: body.note,
        adminId: req.user!.id,
      });
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  router.get('/inventory/movements', async (req, res, next) => {
    try {
      const variantId = req.query.variantId as string | undefined;
      const limit = Number(req.query.limit) || 50;
      const list = await uc.listMovements.execute(variantId, limit);
      res.json(list);
    } catch (err) {
      next(err);
    }
  });

  // Orders
  router.get('/orders', async (req, res, next) => {
    try {
      const query = adminOrdersQuerySchema.parse(req.query);
      const orders = await uc.listOrders.execute(query);
      res.json(orders);
    } catch (err) {
      next(err);
    }
  });

  router.put('/orders/:id/status', async (req, res, next) => {
    try {
      const body = updateOrderStatusSchema.parse(req.body);
      await uc.updateStatus.execute({
        orderId: req.params.id,
        status: body.status,
        note: body.note,
        adminId: req.user!.id,
      });
      res.json({ message: 'Cập nhật trạng thái thành công' });
    } catch (err) {
      next(err);
    }
  });

  // Audit Log & Roles
  router.get('/audit-log', async (req, res, next) => {
    try {
      const limit = Number(req.query.limit) || 50;
      const logs = await uc.listAudit.execute(limit);
      res.json(logs);
    } catch (err) {
      next(err);
    }
  });

  router.put('/users/:id/role', async (req, res, next) => {
    try {
      const body = setUserRoleSchema.parse(req.body);
      await uc.setUserRole.execute(req.params.id, body.role);
      res.json({ message: 'Gán vai trò thành công' });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
