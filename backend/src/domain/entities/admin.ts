import { OrderStatus } from './order.js';

export type InventoryMovementReason =
  | 'order_created'
  | 'order_cancelled'
  | 'admin_restock'
  | 'admin_correction';

export interface InventoryMovement {
  id: string;
  variantId: string;
  change: number;
  reason: InventoryMovementReason;
  orderId?: string | null;
  createdBy?: string | null;
  note?: string | null;
  createdAt: string;
}

export interface OrderStatusHistory {
  id: string;
  orderId: string;
  fromStatus?: OrderStatus | null;
  toStatus: OrderStatus;
  changedBy?: string | null;
  note?: string | null;
  createdAt: string;
}

export interface AdminAuditLog {
  id: string;
  adminId: string;
  action: string;
  entityType: string;
  entityId?: string | null;
  before?: unknown;
  after?: unknown;
  createdAt: string;
}
