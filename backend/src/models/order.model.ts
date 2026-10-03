import { SupabaseClient } from '@supabase/supabase-js';
import {
  Order,
  OrderStatus,
  OrderStatusHistoryEntry,
  ShippingInfo,
  Cursor,
  AppError,
} from './types.js';
import { MOCK_PRODUCTS } from './mock-data.js';

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
  voucherCode?: string | null;
  discountAmount?: number;
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
  getStatusHistory(orderId: string): Promise<OrderStatusHistoryEntry[]>;
}

export const DEFAULT_MOCK_ORDERS: Order[] = [];

export class OrderModel implements IOrderModel {
  private inMemoryOrders: Order[] = [];

  constructor(
    private readonly supabase?: SupabaseClient,
    initialOrders: Order[] = []
  ) {
    this.inMemoryOrders = [...initialOrders];
  }

  async create(input: CreateOrderInput): Promise<string> {
    if (this.supabase) {
      let effectiveUserId = input.userId;
      if (
        input.userId === 'usr-admin-001' ||
        input.userId === '00000000-0000-0000-0000-000000000001' ||
        input.userEmail === 'admin@menshop.vn' ||
        input.userEmail === 'admin@gmail.com'
      ) {
        effectiveUserId = '0f444d92-322c-4956-b452-0c5c10950508';
      } else if (
        input.userId === 'usr-staff-001' ||
        input.userEmail === 'staff@menshop.vn' ||
        input.userEmail === 'staff@gmail.com'
      ) {
        effectiveUserId = 'd604e122-aa50-47e0-ac44-10a2473af6ce';
      } else if (
        !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(effectiveUserId)
      ) {
        effectiveUserId = '7fb74d58-4155-4ab5-8124-cb0b5bb6651d';
      }

      try {
        const { data, error } = await this.supabase.rpc('create_order', {
          p_user_id: effectiveUserId,
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

        if (!error && data) {
          const createdOrderId = data as string;
          if (input.voucherCode || (input.discountAmount && input.discountAmount > 0) || input.note) {
            try {
              const { data: ord } = await this.supabase
                .from('orders')
                .select('subtotal, shipping_fee')
                .eq('id', createdOrderId)
                .single();
              if (ord) {
                const sub = ord.subtotal || 0;
                const ship = ord.shipping_fee || 0;
                const disc = input.discountAmount || 0;
                const finalTotal = Math.max(0, sub - disc + ship);
                await this.supabase
                  .from('orders')
                  .update({
                    voucher_code: input.voucherCode || null,
                    discount_amount: disc,
                    total: finalTotal,
                    note: input.note || null,
                  })
                  .eq('id', createdOrderId);
              }
            } catch (vErr) {
              console.warn('Could not update voucher details on order:', vErr);
            }
          }
          return createdOrderId;
        }

        if (error && error.message.includes('OUT_OF_STOCK')) {
          throw new AppError('OUT_OF_STOCK', 409, 'Một số sản phẩm trong giỏ đã hết hàng');
        }

        // Direct table insert fallback if RPC has any error
        console.warn('create_order RPC failed, trying direct Supabase insertion fallback:', error?.message);
        const code = `MS${new Date().toISOString().slice(2, 10).replace(/-/g, '')}${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

        const variantIds = input.items.map((i) => i.variantId);
        const { data: dbVariants } = await this.supabase
          .from('product_variants')
          .select('id, size, color, stock, product:products(name, price)')
          .in('id', variantIds);

        let subtotal = 0;
        const itemsToInsert: any[] = [];
        for (const item of input.items) {
          const v = dbVariants?.find((x: any) => x.id === item.variantId);
          const pName = (v as any)?.product?.name || 'Sản phẩm MenShop';
          const uPrice = (v as any)?.product?.price || 350000;
          subtotal += uPrice * item.quantity;
          itemsToInsert.push({
            variant_id: item.variantId,
            product_name: pName,
            size: v?.size || 'M',
            color: v?.color || 'Tiêu chuẩn',
            unit_price: uPrice,
            quantity: item.quantity,
          });
        }

        const disc = input.discountAmount || 0;
        const total = Math.max(0, subtotal - disc + input.shippingFee);

        const { data: newOrd, error: ordErr } = await this.supabase
          .from('orders')
          .insert({
            code,
            user_id: effectiveUserId,
            status: input.paymentMethod === 'vnpay' ? 'pending_payment' : 'processing',
            payment_method: input.paymentMethod,
            subtotal,
            shipping_fee: input.shippingFee,
            discount_amount: disc,
            voucher_code: input.voucherCode || null,
            total,
            ship_name: input.ship.name,
            ship_phone: input.ship.phone,
            ship_address: input.ship.address,
            note: input.note || null,
            idempotency_key: input.idempotencyKey || null,
            expires_at: input.paymentMethod === 'vnpay' ? new Date(Date.now() + 15 * 60 * 1000).toISOString() : null,
          })
          .select('id')
          .single();

        if (ordErr || !newOrd) {
          throw new AppError('DB_CREATE_ORDER_FAILED', 400, ordErr?.message || 'Không thể tạo đơn hàng');
        }

        const orderId = newOrd.id;
        if (itemsToInsert.length > 0) {
          await this.supabase.from('order_items').insert(
            itemsToInsert.map((item) => ({
              order_id: orderId,
              ...item,
            }))
          );

          // Deduct variant stock & record inventory movements
          for (const item of input.items) {
            const v = dbVariants?.find((x: any) => x.id === item.variantId);
            const currentStock = v?.stock ?? 100;
            const newStock = Math.max(0, currentStock - item.quantity);
            await this.supabase
              .from('product_variants')
              .update({ stock: newStock })
              .eq('id', item.variantId);

            await this.supabase.from('inventory_movements').insert({
              variant_id: item.variantId,
              change: -item.quantity,
              reason: 'order_created',
              order_id: orderId,
              created_by: effectiveUserId,
              note: 'Khách đặt hàng',
            });
          }
        }

        // Clean cart items
        await this.supabase
          .from('cart_items')
          .delete()
          .eq('user_id', effectiveUserId)
          .in('variant_id', variantIds);

        return orderId;
      } catch (err: any) {
        if (err instanceof AppError) throw err;
        console.warn('Supabase create_order exception:', err.message);
        throw new AppError('DB_CREATE_ORDER_FAILED', 400, err.message);
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
      discountAmount: input.discountAmount || 0,
      voucherCode: input.voucherCode || null,
      total: Math.max(0, subtotal - (input.discountAmount || 0) + input.shippingFee),
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
    return orderId;
  }

  async findById(id: string): Promise<Order | null> {
    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('orders')
          .select(`
            id, code, user_id, status, payment_method, subtotal, shipping_fee, total,
            ship_name, ship_phone, ship_address, idempotency_key, expires_at, created_at,
            note, voucher_code, discount_amount,
            items:order_items(id, order_id, variant_id, product_name, size, color, unit_price, quantity),
            history:order_status_history(id, order_id, from_status, to_status, note, created_at)
          `)
          .or(`id.eq.${id},code.eq.${id}`)
          .maybeSingle();

        if (!error && data) {
          type RawItem = { id: string; order_id: string; variant_id: string; product_name: string; size: string; color: string; unit_price: number; quantity: number };
          type RawHistory = { id: string; order_id: string; from_status: string | null; to_status: string; note: string | null; created_at: string };

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
            note: data.note ?? undefined,
            voucherCode: data.voucher_code ?? null,
            discountAmount: data.discount_amount ?? 0,
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
            statusHistory: ((data.history as unknown as RawHistory[]) || []).map(
              (h) => ({
                status: h.to_status as OrderStatus,
                note: h.note ?? null,
                createdAt: h.created_at,
              })
            ),
          };
        }
      } catch (err: any) {
        console.warn('DB findById exception, checking local store:', err.message);
      }
    }

    return this.inMemoryOrders.find((o) => o.id === id || o.code === id) || null;
  }

  async getStatusHistory(orderId: string): Promise<OrderStatusHistoryEntry[]> {
    if (this.supabase) {
      const isOrderUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(orderId);

      let resolvedId = orderId;
      if (!isOrderUuid) {
        const { data: byCode } = await this.supabase
          .from('orders')
          .select('id')
          .eq('code', orderId)
          .maybeSingle();
        if (!byCode?.id) return [];
        resolvedId = byCode.id;
      }

      const { data, error } = await this.supabase
        .from('order_status_history')
        .select('to_status, note, created_at')
        .eq('order_id', resolvedId)
        .order('created_at', { ascending: true })
        .order('id', { ascending: true });

      if (error || !data) return [];

      return (data as any[])
        .filter((h) => h?.to_status)
        .map((h) => ({
          status: h.to_status as OrderStatus,
          note: h.note ?? null,
          createdAt: h.created_at,
        }));
    }

    // Fallback in-memory: dựng lịch sử tối thiểu từ đơn đang lưu
    const order = this.inMemoryOrders.find((o) => o.id === orderId || o.code === orderId);
    if (!order) return [];
    return [{ status: order.status, note: null, createdAt: order.createdAt }];
  }

  async listByUser(
    userId: string,
    limit: number,
    cursor?: Cursor,
    userEmail?: string,
    headerUserId?: string
  ): Promise<Order[]> {
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

      return mapped.slice(0, limit);
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

      return mapped.slice(0, limit);
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

  async updateStatus(orderId: string, status: OrderStatus, note?: string): Promise<boolean> {
    let updated = false;
    const order = this.inMemoryOrders.find((o) => o.id === orderId || o.code === orderId);
    if (order) {
      if (order.status === 'cancelled' && status !== 'cancelled') {
        throw new AppError('ORDER_ALREADY_CANCELLED', 400, 'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác');
      }
      order.status = status;
      if (note) order.note = note;
      order.statusHistory = [
        ...(order.statusHistory ?? []),
        { status, note: note ?? null, createdAt: new Date().toISOString() },
      ];
      updated = true;
    }
    if (this.supabase) {
      try {
        const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(orderId);

        // Phải đọc trạng thái cũ TRƯỚC khi update, nếu không from_status
        // sẽ bị ghi nhầm bằng trạng thái mới.
        const previousStatus = await this.readStatus(orderId, isUuid);

        let qb = this.supabase.from('orders').update({ status });
        if (isUuid) {
          qb = qb.eq('id', orderId);
        } else {
          qb = qb.eq('code', orderId);
        }
        const { error } = await qb;
        if (!error) {
          updated = true;
          await this.recordStatusHistory(
            orderId,
            status,
            note,
            isUuid,
            previousStatus
          );
        }
      } catch (err: any) {
        console.warn('Supabase updateStatus warning:', err.message);
      }
    }
    return updated;
  }

  /** Đọc trạng thái hiện tại của đơn (theo id hoặc mã đơn) */
  private async readStatus(
    orderId: string,
    isUuid?: boolean
  ): Promise<OrderStatus | null> {
    if (!this.supabase) return null;
    try {
      const uuid = isUuid ?? /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(orderId);
      let qb = this.supabase.from('orders').select('status');
      qb = uuid ? qb.eq('id', orderId) : qb.eq('code', orderId);
      const { data, error } = await qb.maybeSingle();
      if (error || !data) return null;
      return data.status as OrderStatus;
    } catch {
      return null;
    }
  }

  /** Ghi một mốc vào order_status_history (bỏ qua nếu bảng chưa tồn tại) */
  private async recordStatusHistory(
    orderId: string,
    toStatus: OrderStatus,
    note?: string,
    isOrderUuid?: boolean,
    fromStatus?: OrderStatus | null
  ): Promise<void> {
    if (!this.supabase) return;

    try {
      const uuid = isOrderUuid ?? /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(orderId);

      let resolvedId = orderId;
      if (!uuid) {
        const { data: byCode } = await this.supabase
          .from('orders')
          .select('id')
          .eq('code', orderId)
          .maybeSingle();
        if (!byCode?.id) return;
        resolvedId = byCode.id;
      }

      // Nếu không lấy được trạng thái cũ (đơn mới tạo) thì from_status = null
      const { error } = await this.supabase.from('order_status_history').insert({
        order_id: resolvedId,
        from_status: fromStatus ?? null,
        to_status: toStatus,
        note: note ?? null,
      });
      if (error) {
        console.warn('Could not record order status history:', error.message);
      }
    } catch (err: any) {
      console.warn('Could not record order status history:', err.message);
    }
  }
}
