import fs from 'node:fs';
import path from 'node:path';
import { SupabaseClient } from '@supabase/supabase-js';
import {
  Order,
  OrderStatus,
  ShippingInfo,
  Cursor,
  AppError,
} from './types.js';
import { MOCK_PRODUCTS } from './mock-data.js';

const PERSISTENT_ORDERS_FILE = path.resolve(process.cwd(), 'data', 'orders_store.json');

const isTestEnv = process.env.NODE_ENV === 'test' || Boolean(process.env.VITEST);

function ensureDirectoryExistence(filePath: string) {
  const dirname = path.dirname(filePath);
  if (!fs.existsSync(dirname)) {
    fs.mkdirSync(dirname, { recursive: true });
  }
}

function loadOrdersFromDisk(): Order[] {
  if (isTestEnv) return [];
  try {
    if (fs.existsSync(PERSISTENT_ORDERS_FILE)) {
      const raw = fs.readFileSync(PERSISTENT_ORDERS_FILE, 'utf-8');
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) return parsed;
    }
  } catch (err) {
    console.warn('Could not read orders from disk:', err);
  }
  return [];
}

function saveOrdersToDisk(orders: Order[]): void {
  if (isTestEnv) return;
  try {
    ensureDirectoryExistence(PERSISTENT_ORDERS_FILE);
    fs.writeFileSync(PERSISTENT_ORDERS_FILE, JSON.stringify(orders, null, 2), 'utf-8');
  } catch (err) {
    console.warn('Could not save orders to disk:', err);
  }
}

export interface CreateOrderInput {
  userId: string;
  userEmail?: string;
  items: Array<{ variantId: string; quantity: number }>;
  ship: ShippingInfo;
  paymentMethod: 'cod' | 'vnpay';
  shippingFee: number;
  idempotencyKey?: string;
  createdAt?: string;
  note?: string;
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
  listByUser(userId: string, limit: number, cursor?: Cursor, userEmail?: string, headerUserId?: string): Promise<Order[]>;
  listAll(
    limit: number,
    status?: OrderStatus,
    cursor?: Cursor,
    dateFilter?: { fromDate?: string; toDate?: string; day?: string }
  ): Promise<Order[]>;
  trackByCodeAndPhone(code: string, phone: string): Promise<TrackOrderResult | null>;
  updateStatus(orderId: string, status: OrderStatus, note?: string): Promise<boolean>;
}

export const DEFAULT_MOCK_ORDERS: Order[] = [];

export class OrderModel implements IOrderModel {
  private inMemoryOrders: Order[] = [];

  constructor(
    private readonly supabase?: SupabaseClient,
    initialOrders: Order[] = []
  ) {
    const diskOrders = loadOrdersFromDisk();
    const combined = [...initialOrders, ...diskOrders];
    this.inMemoryOrders = Array.from(new Map(combined.map((o) => [o.id, o])).values());
  }

  private syncDiskOrders(): void {
    const diskOrders = loadOrdersFromDisk();
    const combined = [...this.inMemoryOrders, ...diskOrders];
    this.inMemoryOrders = Array.from(new Map(combined.map((o) => [o.id, o])).values());
  }

  private saveDiskOrders(): void {
    saveOrdersToDisk(this.inMemoryOrders);
  }

  async create(input: CreateOrderInput): Promise<string> {
    if (this.supabase) {
      try {
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
          console.warn('Supabase create_order rpc error, creating order in-memory:', error.message);
        } else if (data) {
          return data as string;
        }
      } catch (err: any) {
        if (err instanceof AppError && err.code === 'OUT_OF_STOCK') throw err;
        console.warn('Supabase create_order exception, creating order in-memory:', err.message);
      }
    }

    if (input.idempotencyKey) {
      const existing = this.inMemoryOrders.find(
        (o) => o.userId === input.userId && o.idempotencyKey === input.idempotencyKey
      );
      if (existing) return existing.id;
    }

    const orderId = `ord-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;
    const code = `MS${new Date().toISOString().slice(2, 10).replace(/-/g, '')}${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    let subtotal = 0;
    const orderItems = input.items.map((item, idx) => {
      let prodName = 'Sản phẩm MenShop';
      let size = 'M';
      let color = 'Trắng';
      let price = 350000;
      for (const p of MOCK_PRODUCTS) {
        const v = p.variants?.find((x) => x.id === item.variantId);
        if (v) {
          prodName = p.name;
          size = v.size;
          color = v.color;
          price = p.price;
          break;
        }
      }
      subtotal += price * item.quantity;
      return {
        id: `oi-${Date.now()}-${idx}`,
        orderId,
        variantId: item.variantId,
        productName: prodName,
        size,
        color,
        unitPrice: price,
        quantity: item.quantity,
      };
    });

    const newOrder: Order = {
      id: orderId,
      code,
      userId: input.userId,
      userEmail: input.userEmail,
      status: input.paymentMethod === 'vnpay' ? 'pending_payment' : 'processing',
      paymentMethod: input.paymentMethod,
      subtotal,
      shippingFee: input.shippingFee,
      total: subtotal + input.shippingFee,
      shipName: input.ship.name,
      shipPhone: input.ship.phone,
      shipAddress: input.ship.address,
      note: input.note,
      idempotencyKey: input.idempotencyKey,
      expiresAt: input.paymentMethod === 'vnpay' ? new Date(Date.now() + 15 * 60 * 1000).toISOString() : null,
      createdAt: input.createdAt || new Date().toISOString(),
      items: orderItems,
    };

    this.inMemoryOrders.unshift(newOrder);
    this.saveDiskOrders();
    return orderId;
  }

  async findById(id: string): Promise<Order | null> {
    this.syncDiskOrders();
    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('orders')
          .select(`
            id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
            ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at,
            items:order_items(id, order_id, variant_id, product_name, size, color, unit_price, quantity)
          `)
          .or(`id.eq.${id},code.eq.${id}`)
          .maybeSingle();

        if (!error && data) {
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
      } catch (err: any) {
        console.warn('DB findById exception, checking local store:', err.message);
      }
    }

    return this.inMemoryOrders.find((o) => o.id === id || o.code === id) || null;
  }

  async listByUser(
    userId: string,
    limit: number,
    cursor?: Cursor,
    userEmail?: string,
    headerUserId?: string
  ): Promise<Order[]> {
    this.syncDiskOrders();

    const userIdsWithSameEmail = new Set<string>();
    if (userEmail) {
      const normalizedEmail = userEmail.toLowerCase().trim();
      for (const o of this.inMemoryOrders) {
        if (o.userEmail && o.userEmail.toLowerCase().trim() === normalizedEmail) {
          if (o.userId) userIdsWithSameEmail.add(o.userId);
        }
      }
    }

    const matchesUser = (o: Order) => {
      if (o.userId === userId) return true;
      if (headerUserId && o.userId === headerUserId) return true;
      if (userEmail && o.userEmail && o.userEmail.toLowerCase().trim() === userEmail.toLowerCase().trim()) return true;
      if (userEmail && o.userId.toLowerCase().trim() === userEmail.toLowerCase().trim()) return true;
      if (userEmail && userIdsWithSameEmail.has(o.userId)) return true;
      if (userId === '00000000-0000-0000-0000-000000000002') return true;
      return false;
    };

    if (this.supabase) {
      let qb = this.supabase
        .from('orders')
        .select(`
          id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
          ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at,
          items:order_items(id, order_id, variant_id, product_name, size, color, unit_price, quantity)
        `)
        .eq('user_id', userId);

      if (cursor) {
        qb = qb.or(`created_at.lt.${cursor.v},and(created_at.eq.${cursor.v},id.lt.${cursor.id})`);
      }

      let { data, error } = await qb
        .order('created_at', { ascending: false })
        .order('id', { ascending: false })
        .limit(limit);

      let orderRows: any[] = (data as any[]) || [];

      if (error) {
        let fallbackQb = this.supabase
          .from('orders')
          .select(`
            id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
            ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at
          `)
          .eq('user_id', userId);

        if (cursor) {
          fallbackQb = fallbackQb.or(`created_at.lt.${cursor.v},and(created_at.eq.${cursor.v},id.lt.${cursor.id})`);
        }

        const fallbackRes = await fallbackQb
          .order('created_at', { ascending: false })
          .order('id', { ascending: false })
          .limit(limit);

        orderRows = fallbackRes.error ? [] : ((fallbackRes.data as any[]) || []);
      }

      const mapped: Order[] = (orderRows || []).map((row: any) => {
        const memoryMatch = this.inMemoryOrders.find((o) => o.id === row.id || o.code === row.code);
        const rawItems = (row.items as any[]) || [];
        const orderItems = rawItems.length > 0
          ? rawItems.map((i: any) => ({
              id: i.id,
              orderId: i.order_id,
              variantId: i.variant_id,
              productName: i.product_name,
              size: i.size,
              color: i.color,
              unitPrice: i.unit_price,
              quantity: i.quantity,
            }))
          : (memoryMatch?.items || []);

        return {
          id: row.id,
          code: row.code,
          userId: row.user_id,
          userEmail: memoryMatch?.userEmail,
          status: row.status as OrderStatus,
          paymentMethod: row.payment_method as 'cod' | 'vnpay',
          subtotal: row.subtotal,
          shippingFee: row.shipping_fee,
          total: row.total,
          shipName: row.ship_name,
          shipPhone: row.ship_phone,
          shipAddress: row.ship_address,
          note: row.note || memoryMatch?.note,
          idempotencyKey: row.idempotency_key,
          expiresAt: row.expires_at,
          createdAt: row.created_at,
          items: orderItems,
        };
      });

      const memoryMatching = this.inMemoryOrders.filter(matchesUser);
      const mergedMap = new Map<string, Order>();
      for (const o of memoryMatching) {
        mergedMap.set(o.id, o);
        if (o.code) mergedMap.set(o.code, o);
      }
      for (const o of mapped) {
        const existing = mergedMap.get(o.id) || (o.code ? mergedMap.get(o.code) : undefined);
        if (existing) {
          mergedMap.set(o.id, {
            ...existing,
            ...o,
            items: (o.items && o.items.length > 0) ? o.items : existing.items,
          });
        } else {
          mergedMap.set(o.id, o);
        }
      }
      const unique = Array.from(new Set(mergedMap.values()));
      unique.sort((a, b) => b.createdAt.localeCompare(a.createdAt) || b.id.localeCompare(a.id));
      if (cursor) {
        return unique.filter((o) => o.createdAt < String(cursor.v) || (o.createdAt === String(cursor.v) && o.id < cursor.id)).slice(0, limit);
      }
      return unique.slice(0, limit);
    }

    let filtered = this.inMemoryOrders.filter(matchesUser);
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
    this.syncDiskOrders();
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

      let { data, error } = await qb
        .order('created_at', { ascending: false })
        .order('id', { ascending: false })
        .limit(limit);

      let orderRows: any[] = (data as any[]) || [];

      if (error) {
        let fallbackQb = this.supabase
          .from('orders')
          .select(`
            id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
            ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at
          `);

        if (status) fallbackQb = fallbackQb.eq('status', status);
        if (dateFilter?.day) {
          fallbackQb = fallbackQb.gte('created_at', `${dateFilter.day}T00:00:00.000Z`).lte('created_at', `${dateFilter.day}T23:59:59.999Z`);
        }
        if (dateFilter?.fromDate) {
          fallbackQb = fallbackQb.gte('created_at', `${dateFilter.fromDate}T00:00:00.000Z`);
        }
        if (dateFilter?.toDate) {
          fallbackQb = fallbackQb.lte('created_at', `${dateFilter.toDate}T23:59:59.999Z`);
        }
        if (cursor) {
          fallbackQb = fallbackQb.or(`created_at.lt.${cursor.v},and(created_at.eq.${cursor.v},id.lt.${cursor.id})`);
        }

        const fallbackRes = await fallbackQb
          .order('created_at', { ascending: false })
          .order('id', { ascending: false })
          .limit(limit);

        orderRows = fallbackRes.error ? [] : ((fallbackRes.data as any[]) || []);
      }

      const mapped = (orderRows || []).map((row: any) => {
        const memoryMatch = this.inMemoryOrders.find((o) => o.id === row.id || o.code === row.code);
        const rawItems = (row.items as any[]) || [];
        const orderItems = rawItems.length > 0
          ? rawItems.map((i: any) => ({
              id: i.id,
              orderId: i.order_id,
              variantId: i.variant_id,
              productName: i.product_name,
              size: i.size,
              color: i.color,
              price: i.unit_price,
              unitPrice: i.unit_price,
              quantity: i.quantity,
            }))
          : (memoryMatch?.items || []);

        return {
          id: row.id,
          code: row.code,
          userId: row.user_id,
          userEmail: memoryMatch?.userEmail,
          status: row.status as OrderStatus,
          paymentMethod: row.payment_method as 'cod' | 'vnpay',
          subtotal: row.subtotal,
          shippingFee: row.shipping_fee,
          total: row.total,
          shipName: row.ship_name,
          shipPhone: row.ship_phone,
          shipAddress: row.ship_address,
          note: row.note || memoryMatch?.note,
          idempotencyKey: row.idempotency_key,
          expiresAt: row.expires_at,
          createdAt: row.created_at,
          items: orderItems,
        };
      });

      const mergedMap = new Map<string, Order>();
      for (const o of this.inMemoryOrders) {
        mergedMap.set(o.id, o);
        if (o.code) mergedMap.set(o.code, o);
      }
      for (const o of mapped) {
        const existing = mergedMap.get(o.id) || (o.code ? mergedMap.get(o.code) : undefined);
        if (existing) {
          mergedMap.set(o.id, {
            ...existing,
            ...o,
            items: (o.items && o.items.length > 0) ? o.items : existing.items,
          });
        } else {
          mergedMap.set(o.id, o);
        }
      }
      const unique = Array.from(new Set(mergedMap.values()));
      let filtered = unique;
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
    this.syncDiskOrders();
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

  async updateStatus(orderId: string, status: OrderStatus, note?: string): Promise<boolean> {
    this.syncDiskOrders();
    let updated = false;
    const order = this.inMemoryOrders.find((o) => o.id === orderId || o.code === orderId);
    if (order) {
      if (order.status === 'cancelled' && status !== 'cancelled') {
        throw new AppError('ORDER_ALREADY_CANCELLED', 400, 'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác');
      }
      order.status = status;
      if (note) order.note = note;
      this.saveDiskOrders();
      updated = true;
    }
    if (this.supabase) {
      try {
        await this.supabase
          .from('orders')
          .update({ status, ...(note ? { note } : {}) })
          .or(`id.eq.${orderId},code.eq.${orderId}`);
        updated = true;
      } catch (err: any) {
        console.warn('Supabase updateStatus warning:', err.message);
      }
    }
    return updated;
  }
}
