import { SupabaseClient } from '@supabase/supabase-js';
import {
  InventoryMovement,
  InventoryMovementReason,
  AdminAuditLog,
  OrderStatus,
  AppError,
} from './types.js';

export interface IAdminModel {
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

  setUserRole(userId: string, role: 'customer' | 'admin'): Promise<void>;
  listInventoryMovements(variantId?: string, limit?: number): Promise<InventoryMovement[]>;
  listAuditLogs(limit?: number): Promise<AdminAuditLog[]>;
  recordAuditLog(adminId: string, action: string, entityType: string, entityId?: string, before?: unknown, after?: unknown): Promise<void>;
}

export class AdminModel implements IAdminModel {
  private inMemoryMovements: InventoryMovement[] = [];
  private inMemoryLogs: AdminAuditLog[] = [];
  private inMemoryRoles = new Map<string, 'customer' | 'admin'>();

  constructor(private readonly supabase?: SupabaseClient) {}

  async adjustStock(
    variantId: string,
    delta: number,
    reason: InventoryMovementReason,
    note?: string,
    adminId?: string
  ): Promise<number> {
    if (this.supabase) {
      const { data, error } = await this.supabase.rpc('adjust_stock', {
        p_variant_id: variantId,
        p_delta: delta,
        p_reason: reason,
        p_note: note || null,
        p_admin_id: adminId || null,
      });

      if (error) throw new AppError('DB_ADJUST_STOCK_FAILED', 400, error.message);
      return Number(data);
    }

    this.inMemoryMovements.push({
      id: `inv-${Date.now()}`,
      variantId,
      change: delta,
      reason,
      note,
      createdBy: adminId,
      createdAt: new Date().toISOString(),
    });
    return 30; // updated mock stock
  }

  async updateOrderStatus(
    orderId: string,
    newStatus: OrderStatus,
    note?: string,
    adminId?: string
  ): Promise<void> {
    if (this.supabase) {
      const { error } = await this.supabase.rpc('admin_update_order_status', {
        p_order_id: orderId,
        p_new_status: newStatus,
        p_note: note || null,
        p_admin_id: adminId || null,
      });

      if (error) throw new AppError('DB_UPDATE_STATUS_FAILED', 400, error.message);
      return;
    }
  }

  async setUserRole(userId: string, role: 'customer' | 'admin'): Promise<void> {
    if (this.supabase) {
      const { error } = await this.supabase.rpc('set_user_role', {
        p_user_id: userId,
        p_role: role,
      });
      if (error) throw new AppError('DB_SET_ROLE_FAILED', 400, error.message);
      return;
    }

    this.inMemoryRoles.set(userId, role);
  }

  async listInventoryMovements(variantId?: string, limit = 50): Promise<InventoryMovement[]> {
    if (this.supabase) {
      let qb = this.supabase
        .from('inventory_movements')
        .select('id, variant_id, change, reason, order_id, created_by, note, created_at');

      if (variantId) qb = qb.eq('variant_id', variantId);
      const { data, error } = await qb.order('created_at', { ascending: false }).limit(limit);
      if (error) throw new AppError('DB_INVENTORY_FAILED', 500, error.message);

      return (data || []).map((row) => ({
        id: row.id,
        variantId: row.variant_id,
        change: row.change,
        reason: row.reason,
        orderId: row.order_id,
        createdBy: row.created_by,
        note: row.note,
        createdAt: row.created_at,
      }));
    }

    return this.inMemoryMovements.slice(0, limit);
  }

  async listAuditLogs(limit = 50): Promise<AdminAuditLog[]> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('admin_audit_log')
        .select('id, admin_id, action, entity_type, entity_id, before, after, created_at')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw new AppError('DB_AUDIT_LOG_FAILED', 500, error.message);
      return (data || []).map((row) => ({
        id: row.id,
        adminId: row.admin_id,
        action: row.action,
        entityType: row.entity_type,
        entityId: row.entity_id,
        before: row.before,
        after: row.after,
        createdAt: row.created_at,
      }));
    }

    return this.inMemoryLogs.slice(0, limit);
  }

  async recordAuditLog(
    adminId: string,
    action: string,
    entityType: string,
    entityId?: string,
    before?: unknown,
    after?: unknown
  ): Promise<void> {
    if (this.supabase) {
      await this.supabase.from('admin_audit_log').insert({
        admin_id: adminId,
        action,
        entity_type: entityType,
        entity_id: entityId || null,
        before: before || null,
        after: after || null,
      });
      return;
    }

    this.inMemoryLogs.push({
      id: `audit-${Date.now()}`,
      adminId,
      action,
      entityType,
      entityId,
      before,
      after,
      createdAt: new Date().toISOString(),
    });
  }
}
