import { SupabaseClient } from '@supabase/supabase-js';
import {
  InventoryMovement,
  InventoryMovementReason,
  AdminAuditLog,
} from '../../domain/entities/admin.js';
import { OrderStatus } from '../../domain/entities/order.js';
import { AdminRepository } from '../../domain/repositories/admin.repository.js';
import { InfraError } from '../../domain/errors.js';

export class SupabaseAdminRepository implements AdminRepository {
  constructor(private readonly db: SupabaseClient) {}

  async adjustStock(
    variantId: string,
    delta: number,
    reason: InventoryMovementReason,
    note?: string,
    adminId?: string
  ): Promise<number> {
    const { data, error } = await this.db.rpc('adjust_stock', {
      p_variant_id: variantId,
      p_delta: delta,
      p_reason: reason,
      p_note: note || null,
      p_admin_id: adminId || null,
    });

    if (error) {
      throw new InfraError('DB_ADJUST_STOCK_FAILED', error, error.message);
    }

    return Number(data);
  }

  async updateOrderStatus(
    orderId: string,
    newStatus: OrderStatus,
    note?: string,
    adminId?: string
  ): Promise<void> {
    const { error } = await this.db.rpc('admin_update_order_status', {
      p_order_id: orderId,
      p_new_status: newStatus,
      p_note: note || null,
      p_admin_id: adminId || null,
    });

    if (error) {
      throw new InfraError('DB_UPDATE_STATUS_FAILED', error, error.message);
    }
  }

  async setUserRole(userId: string, role: 'customer' | 'admin' | 'staff'): Promise<void> {
    const { error } = await this.db.rpc('set_user_role', {
      p_user_id: userId,
      p_role: role,
    });

    if (error) {
      throw new InfraError('DB_SET_ROLE_FAILED', error, error.message);
    }
  }

  async listInventoryMovements(
    variantId?: string,
    limit = 50
  ): Promise<InventoryMovement[]> {
    let qb = this.db
      .from('inventory_movements')
      .select('id, variant_id, change, reason, order_id, created_by, note, created_at');

    if (variantId) {
      qb = qb.eq('variant_id', variantId);
    }

    const { data, error } = await qb
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      throw new InfraError('DB_INVENTORY_QUERY_FAILED', error);
    }

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

  async listAuditLogs(limit = 50): Promise<AdminAuditLog[]> {
    const { data, error } = await this.db
      .from('admin_audit_log')
      .select('id, admin_id, action, entity_type, entity_id, before, after, created_at')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      throw new InfraError('DB_AUDIT_LOG_QUERY_FAILED', error);
    }

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

  async recordAuditLog(
    adminId: string,
    action: string,
    entityType: string,
    entityId?: string,
    before?: unknown,
    after?: unknown
  ): Promise<void> {
    await this.db.from('admin_audit_log').insert({
      admin_id: adminId,
      action,
      entity_type: entityType,
      entity_id: entityId || null,
      before: before || null,
      after: after || null,
    });
  }
}
