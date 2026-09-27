import { SupabaseClient } from '@supabase/supabase-js';
import { Order, OrderStatus } from '../../domain/entities/order.js';
import {
  OrderRepository,
  CreateOrderInput,
  TrackOrderResult,
} from '../../domain/repositories/order.repository.js';
import { Cursor } from '../../domain/pagination.js';
import { InfraError } from '../../domain/errors.js';

export class SupabaseOrderRepository implements OrderRepository {
  constructor(private readonly db: SupabaseClient) {}

  async create(input: CreateOrderInput): Promise<string> {
    const { data, error } = await this.db.rpc('create_order', {
      p_user_id: input.userId,
      p_items: input.items.map((i) => ({
        variant_id: i.variantId,
        quantity: i.quantity,
      })),
      p_ship: {
        name: input.ship.name,
        phone: input.ship.phone,
        address: input.ship.address,
      },
      p_method: input.paymentMethod,
      p_shipping_fee: input.shippingFee,
      p_idem_key: input.idempotencyKey || null,
    });

    if (error) {
      throw new InfraError('DB_CREATE_ORDER_RPC_FAILED', error, error.message);
    }

    return data as string;
  }

  async findById(id: string): Promise<Order | null> {
    const { data, error } = await this.db
      .from('orders')
      .select(`
        id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
        ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at,
        items:order_items(id, order_id, variant_id, product_name, size, color, unit_price, quantity)
      `)
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new InfraError('DB_ORDER_DETAIL_FAILED', error);
    }
    if (!data) return null;

    type RawItem = { id: string; order_id: string; variant_id: string; product_name: string; size: string; color: string; unit_price: number; quantity: number };

    return {
      id: data.id,
      code: data.code,
      userId: data.user_id,
      status: data.status as OrderStatus,
      paymentMethod: data.payment_method as 'cod' | 'vnpay',
      subtotal: data.subtotal,
      shippingFee: data.shipping_fee,
      total: data.total,
      shipName: data.ship_name,
      shipPhone: data.ship_phone,
      shipAddress: data.ship_address,
      idempotencyKey: data.idempotency_key,
      expiresAt: data.expires_at,
      createdAt: data.created_at,
      items: ((data.items as unknown as RawItem[]) || []).map((i) => ({
        id: i.id,
        orderId: i.order_id,
        variantId: i.variant_id,
        productName: i.product_name,
        size: i.size,
        color: i.color,
        unitPrice: i.unit_price,
        quantity: i.quantity,
      })),
    };
  }

  async listByUser(userId: string, limit: number, cursor?: Cursor): Promise<Order[]> {
    let qb = this.db
      .from('orders')
      .select(`
        id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
        ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at
      `)
      .eq('user_id', userId);

    if (cursor) {
      qb = qb.or(`created_at.lt.${cursor.v},and(created_at.eq.${cursor.v},id.lt.${cursor.id})`);
    }

    const { data, error } = await qb
      .order('created_at', { ascending: false })
      .order('id', { ascending: false })
      .limit(limit);

    if (error) {
      throw new InfraError('DB_USER_ORDERS_FAILED', error);
    }

    return (data || []).map((row) => ({
      id: row.id,
      code: row.code,
      userId: row.user_id,
      status: row.status as OrderStatus,
      paymentMethod: row.payment_method as 'cod' | 'vnpay',
      subtotal: row.subtotal,
      shippingFee: row.shipping_fee,
      total: row.total,
      shipName: row.ship_name,
      shipPhone: row.ship_phone,
      shipAddress: row.ship_address,
      idempotencyKey: row.idempotency_key,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
    }));
  }

  async listAll(
    limit: number,
    status?: OrderStatus,
    cursor?: Cursor,
    dateFilter?: { fromDate?: string; toDate?: string; day?: string }
  ): Promise<Order[]> {
    let qb = this.db
      .from('orders')
      .select(`
        id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
        ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at
      `);

    if (status) {
      qb = qb.eq('status', status);
    }

    if (dateFilter?.day) {
      qb = qb.gte('created_at', `${dateFilter.day}T00:00:00.000Z`).lte('created_at', `${dateFilter.day}T23:59:59.999Z`);
    }
    if (dateFilter?.fromDate) {
      qb = qb.gte('created_at', `${dateFilter.fromDate}T00:00:00.000Z`);
    }
    if (dateFilter?.toDate) {
      qb = qb.lte('created_at', `${dateFilter.toDate}T23:59:59.999Z`);
    }

    if (cursor) {
      qb = qb.or(`created_at.lt.${cursor.v},and(created_at.eq.${cursor.v},id.lt.${cursor.id})`);
    }

    const { data, error } = await qb
      .order('created_at', { ascending: false })
      .order('id', { ascending: false })
      .limit(limit);

    if (error) {
      throw new InfraError('DB_ADMIN_ORDERS_FAILED', error);
    }

    return (data || []).map((row) => ({
      id: row.id,
      code: row.code,
      userId: row.user_id,
      status: row.status as OrderStatus,
      paymentMethod: row.payment_method as 'cod' | 'vnpay',
      subtotal: row.subtotal,
      shippingFee: row.shipping_fee,
      total: row.total,
      shipName: row.ship_name,
      shipPhone: row.ship_phone,
      shipAddress: row.ship_address,
      idempotencyKey: row.idempotency_key,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
    }));
  }

  async trackByCodeAndPhone(code: string, phone: string): Promise<TrackOrderResult | null> {
    const { data, error } = await this.db.rpc('track_order_by_code_phone', {
      p_code: code,
      p_phone: phone,
    });

    if (error) {
      throw new InfraError('DB_TRACK_ORDER_FAILED', error);
    }

    if (!data || !Array.isArray(data) || data.length === 0) {
      return null;
    }

    const row = data[0];
    return {
      id: row.id,
      code: row.code,
      status: row.status as OrderStatus,
      total: row.total,
      paymentMethod: row.payment_method,
      createdAt: row.created_at,
      items: row.items || [],
    };
  }
}
