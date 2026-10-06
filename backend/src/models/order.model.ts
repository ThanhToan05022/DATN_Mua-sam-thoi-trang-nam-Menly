import { SupabaseClient } from '@supabase/supabase-js';
import {
  Order,
  OrderStatus,
  ShippingInfo,
  Cursor,
  AppError,
} from './types.js';

export interface CreateOrderInput {
  userId: string;
  items: Array<{ variantId: string; quantity: number }>;
  ship: ShippingInfo;
  paymentMethod: 'cod' | 'vnpay';
  shippingFee: number;
  idempotencyKey?: string;
  createdAt?: string;
}

export interface TrackOrderResult {
  id: string;
  code: string;
  status: OrderStatus;
  total: number;
  paymentMethod: string;
  createdAt: string;
  items: Array<{
    productName: string;
    size: string;
    color: string;
    quantity: number;
    unitPrice: number;
  }>;
}

export interface IOrderModel {
  create(input: CreateOrderInput): Promise<string>;
  findById(id: string): Promise<Order | null>;
  listAll(
    limit: number,
    status?: OrderStatus,
    cursor?: Cursor,
    dateFilter?: { fromDate?: string; toDate?: string; day?: string }
  ): Promise<Order[]>;
  trackByCodeAndPhone(code: string, phone: string): Promise<TrackOrderResult | null>;
}

export class OrderModel implements IOrderModel {
  private inMemoryOrders: Order[] = [];

  constructor(private readonly supabase?: SupabaseClient) {}

  async create(input: CreateOrderInput): Promise<string> {
    if (this.supabase) {
      const { data, error } = await this.supabase.rpc('create_order', {
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
        if (error.message.includes('OUT_OF_STOCK')) {
          throw new AppError('OUT_OF_STOCK', 409, 'Một số sản phẩm trong giỏ đã hết hàng');
        }
        throw new AppError('DB_CREATE_ORDER_FAILED', 500, error.message);
      }

      return data as string;
    }

    if (input.idempotencyKey) {
      const existing = this.inMemoryOrders.find(
        (o) => o.userId === input.userId && o.idempotencyKey === input.idempotencyKey
      );
      if (existing) return existing.id;
    }

    const orderId = `ord-${Date.now()}`;
    const code = `MS${new Date().toISOString().slice(2, 10).replace(/-/g, '')}${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    let subtotal = 0;
    const orderItems = input.items.map((item, idx) => {
      const price = 350000;
      subtotal += price * item.quantity;
      return {
        id: `oi-${Date.now()}-${idx}`,
        orderId,
        variantId: item.variantId,
        productName: 'Áo Sơ Mi Trắng Oxford',
        size: 'M',
        color: 'Trắng',
        unitPrice: price,
        quantity: item.quantity,
      };
    });

    const newOrder: Order = {
      id: orderId,
      code,
      userId: input.userId,
      status: input.paymentMethod === 'vnpay' ? 'pending_payment' : 'processing',
      paymentMethod: input.paymentMethod,
      subtotal,
      shippingFee: input.shippingFee,
      total: subtotal + input.shippingFee,
      shipName: input.ship.name,
      shipPhone: input.ship.phone,
      shipAddress: input.ship.address,
      idempotencyKey: input.idempotencyKey,
      expiresAt: input.paymentMethod === 'vnpay' ? new Date(Date.now() + 15 * 60 * 1000).toISOString() : null,
      createdAt: input.createdAt || new Date().toISOString(),
      items: orderItems,
    };

    this.inMemoryOrders.push(newOrder);
    return orderId;
  }

  async findById(id: string): Promise<Order | null> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('orders')
        .select(`
          id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
          ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at,
          items:order_items(id, order_id, variant_id, product_name, size, color, unit_price, quantity)
        `)
        .eq('id', id)
        .maybeSingle();

      if (error) throw new AppError('DB_ORDER_FAILED', 500, error.message);
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

    return this.inMemoryOrders.find((o) => o.id === id) || null;
  }

  async listByUser(userId: string, limit: number, cursor?: Cursor): Promise<Order[]> {
    if (this.supabase) {
      let qb = this.supabase
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

      if (error) throw new AppError('DB_ORDERS_FAILED', 500, error.message);
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

    let filtered = this.inMemoryOrders.filter((o) => o.userId === userId);
    filtered.sort((a, b) => b.createdAt.localeCompare(a.createdAt) || b.id.localeCompare(a.id));
    if (cursor) {
      filtered = filtered.filter((o) => o.createdAt < String(cursor.v) || (o.createdAt === String(cursor.v) && o.id < cursor.id));
    }
    return filtered.slice(0, limit);
  }

  async listAll(
    limit: number,
    status?: OrderStatus,
    cursor?: Cursor,
    dateFilter?: { fromDate?: string; toDate?: string; day?: string }
  ): Promise<Order[]> {
    if (this.supabase) {
      let qb = this.supabase
        .from('orders')
        .select(`
          id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
          ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at,
          items:order_items(id, order_id, variant_id, product_name, size, color, unit_price, quantity)
        `);

      if (status) qb = qb.eq('status', status);
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

      if (error) throw new AppError('DB_ORDERS_ADMIN_FAILED', 500, error.message);
      return (data || []).map((row: any) => ({
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
        items: ((row.items as any[]) || []).map((i) => ({
          id: i.id,
          orderId: i.order_id,
          variantId: i.variant_id,
          productName: i.product_name,
          size: i.size,
          color: i.color,
          price: i.unit_price,
          unitPrice: i.unit_price,
          quantity: i.quantity,
        })),
      }));
    }

    let filtered = this.inMemoryOrders;
    if (status) filtered = filtered.filter((o) => o.status === status);
    if (dateFilter?.day) {
      filtered = filtered.filter((o) => o.createdAt.slice(0, 10) === dateFilter.day);
    }
    if (dateFilter?.fromDate) {
      filtered = filtered.filter((o) => o.createdAt.slice(0, 10) >= dateFilter.fromDate!);
    }
    if (dateFilter?.toDate) {
      filtered = filtered.filter((o) => o.createdAt.slice(0, 10) <= dateFilter.toDate!);
    }
    filtered.sort((a, b) => b.createdAt.localeCompare(a.createdAt) || b.id.localeCompare(a.id));
    if (cursor) {
      filtered = filtered.filter((o) => o.createdAt < String(cursor.v) || (o.createdAt === String(cursor.v) && o.id < cursor.id));
    }
    return filtered.slice(0, limit);
  }

  async trackByCodeAndPhone(code: string, phone: string): Promise<TrackOrderResult | null> {
    if (this.supabase) {
      const { data, error } = await this.supabase.rpc('track_order_by_code_phone', {
        p_code: code,
        p_phone: phone,
      });

      if (error) throw new AppError('DB_TRACK_ORDER_FAILED', 500, error.message);
      if (!data || !Array.isArray(data) || data.length === 0) return null;

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

    const o = this.inMemoryOrders.find((ord) => ord.code === code && ord.shipPhone === phone);
    if (!o) return null;
    return {
      id: o.id,
      code: o.code,
      status: o.status,
      total: o.total,
      paymentMethod: o.paymentMethod,
      createdAt: o.createdAt,
      items: (o.items || []).map((i) => ({
        productName: i.productName,
        size: i.size,
        color: i.color,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
      })),
    };
  }
}
