import {
  Order,
  Page,
  OrderStatus,
  InventoryMovement,
  AdminAuditLog,
  InventoryMovementReason,
  AppError,
} from '../models/types.js';
import { IAdminModel } from '../models/admin.model.js';
import { IOrderModel } from '../models/order.model.js';
import { decodeCursor, encodeCursor } from './base.viewmodel.js';

export class AdminViewModel {
  constructor(
    private readonly adminModel: IAdminModel,
    private readonly orderModel: IOrderModel
  ) {}

  async adjustStock(
    variantId: string,
    delta: number,
    reason: 'admin_restock' | 'admin_correction',
    note?: string,
    adminId?: string
  ): Promise<{ newStock: number }> {
    if (reason !== 'admin_restock' && reason !== 'admin_correction') {
      throw new AppError('INVALID_REASON', 400, 'Lý do điều chỉnh không hợp lệ');
    }
    const newStock = await this.adminModel.adjustStock(
      variantId,
      delta,
      reason as InventoryMovementReason,
      note,
      adminId
    );
    return { newStock };
  }

  async updateOrderStatus(orderId: string, status: OrderStatus, note?: string, adminId?: string): Promise<void> {
    await this.adminModel.updateOrderStatus(orderId, status, note, adminId);
  }

  async listOrders(
    limit: number,
    status?: OrderStatus,
    cursor?: string,
    fromDate?: string,
    toDate?: string,
    day?: string
  ): Promise<Page<Order>> {
    const orders = await this.orderModel.listAll(
      limit + 1,
      status,
      cursor ? decodeCursor(cursor) : undefined,
      fromDate || toDate || day ? { fromDate, toDate, day } : undefined
    );

    const hasNext = orders.length > limit;
    const items = hasNext ? orders.slice(0, limit) : orders;
    const last = items.at(-1);

    return {
      items,
      pageInfo: {
        limit,
        hasNext,
        nextCursor: hasNext && last ? encodeCursor({ v: last.createdAt, id: last.id }) : null,
      },
    };
  }

  async setUserRole(userId: string, role: 'customer' | 'admin'): Promise<void> {
    if (role !== 'customer' && role !== 'admin') {
      throw new AppError('INVALID_ROLE', 400, 'Vai trò không hợp lệ');
    }
    await this.adminModel.setUserRole(userId, role);
  }

  async listMovements(variantId?: string, limit = 50): Promise<InventoryMovement[]> {
    return this.adminModel.listInventoryMovements(variantId, limit);
  }

  async listAudit(limit = 50): Promise<AdminAuditLog[]> {
    return this.adminModel.listAuditLogs(limit);
  }
}
