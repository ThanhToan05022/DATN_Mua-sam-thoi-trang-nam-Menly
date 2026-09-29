import {
  InventoryMovement,
  InventoryMovementReason,
  OrderStatusHistory,
  AdminAuditLog,
} from '../entities/admin.js';
import { OrderStatus } from '../entities/order.js';

export interface AdminRepository {
  adjustStock(
    variantId: string,
    delta: number,
    reason: InventoryMovementReason,
    note?: string,
    adminId?: string
  ): Promise<number>;

  updateOrderStatus(
    orderId: string,
    newStatus: OrderStatus,
    note?: string,
    adminId?: string
  ): Promise<void>;

  setUserRole(userId: string, role: 'customer' | 'admin' | 'staff'): Promise<void>;

  listInventoryMovements(variantId?: string, limit?: number): Promise<InventoryMovement[]>;

  listAuditLogs(limit?: number): Promise<AdminAuditLog[]>;

  recordAuditLog(
    adminId: string,
    action: string,
    entityType: string,
    entityId?: string,
    before?: unknown,
    after?: unknown
  ): Promise<void>;
}
