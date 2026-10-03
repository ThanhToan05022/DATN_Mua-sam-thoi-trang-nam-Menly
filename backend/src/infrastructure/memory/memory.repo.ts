import { Category } from '../../domain/entities/category.js';
import { ProductSummary, ProductDetail } from '../../domain/entities/product.js';
import { Cart, CartItem } from '../../domain/entities/cart.js';
import { Order, OrderStatus } from '../../domain/entities/order.js';
import { Payment } from '../../domain/entities/payment.js';
import {
  InventoryMovement,
  InventoryMovementReason,
  AdminAuditLog,
} from '../../domain/entities/admin.js';
import { CategoryRepository } from '../../domain/repositories/category.repository.js';
import { ProductRepository, ProductQuery } from '../../domain/repositories/product.repository.js';
import { CartRepository } from '../../domain/repositories/cart.repository.js';
import {
  OrderRepository,
  CreateOrderInput,
  TrackOrderResult,
} from '../../domain/repositories/order.repository.js';
import {
  PaymentRepository,
  CreatePaymentRecord,
  SettlePaymentInput,
} from '../../domain/repositories/payment.repository.js';
import { AdminRepository } from '../../domain/repositories/admin.repository.js';
import { Cursor } from '../../domain/pagination.js';
import { AppError } from '../../domain/errors.js';

// Shared in-memory data store
export class InMemoryStore {
  categories: Category[] = [
    { id: 'c1111111-1111-1111-1111-111111111111', name: 'Áo Sơ Mi Nam', slug: 'ao-so-mi-nam', sortOrder: 1 },
    { id: 'c2222222-2222-2222-2222-222222222222', name: 'Áo Polo & T-Shirt', slug: 'ao-polo-t-shirt', sortOrder: 2 },
    { id: 'c3333333-3333-3333-3333-333333333333', name: 'Quần Tây & Kaki', slug: 'quan-tay-kaki', sortOrder: 3 },
    { id: 'c4444444-4444-4444-4444-444444444444', name: 'Quần Jeans Nam', slug: 'quan-jeans-nam', sortOrder: 4 },
  ];

  products: ProductDetail[] = [
    {
      id: 'a1111111-1111-1111-1111-111111111111',
      categoryId: 'c1111111-1111-1111-1111-111111111111',
      name: 'Áo Sơ Mi Trắng Oxford Dài Tay',
      slug: 'ao-so-mi-trang-oxford-dai-tay',
      description: 'Áo sơ mi vải oxford cao cấp, form slim-fit thanh lịch.',
      price: 350000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600',
      isActive: true,
      createdAt: '2026-09-20T10:00:00.000000Z',
      variants: [
        { id: 'b1111111-1111-1111-1111-111111111111', productId: 'a1111111-1111-1111-1111-111111111111', size: 'M', color: 'Trắng', sku: 'SM-WHT-M', stock: 25 },
        { id: 'b1111111-1111-1111-1111-111111111112', productId: 'a1111111-1111-1111-1111-111111111111', size: 'L', color: 'Trắng', sku: 'SM-WHT-L', stock: 30 },
      ],
      images: [
        { id: 'img-1', productId: 'a1111111-1111-1111-1111-111111111111', url: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600', sortOrder: 1 },
      ],
    },
    {
      id: 'a2222222-2222-2222-2222-222222222222',
      categoryId: 'c2222222-2222-2222-2222-222222222222',
      name: 'Áo Polo Pique Cotton Thoáng Khí',
      slug: 'ao-polo-pique-cotton-thoang-khi',
      description: 'Áo polo phối cổ dệt rib, chất liệu cotton mềm mại.',
      price: 290000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1586363104862-3a5e2ab60d99?w=600',
      isActive: true,
      createdAt: '2026-09-21T10:00:00.000000Z',
      variants: [
        { id: 'b2222222-2222-2222-2222-222222222221', productId: 'a2222222-2222-2222-2222-222222222222', size: 'M', color: 'Đen', sku: 'PL-BLK-M', stock: 20 },
      ],
      images: [],
    },
    {
      id: 'p3333333-3333-3333-3333-333333333333',
      categoryId: 'c3333333-3333-3333-3333-333333333333',
      name: 'Quần Tây Regular Fit Co Giãn',
      slug: 'quan-tay-regular-fit-co-gian',
      description: 'Quần âu phong cách Hàn Quốc, co giãn nhẹ.',
      price: 420000,
      thumbnailUrl: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600',
      isActive: true,
      createdAt: '2026-09-22T10:00:00.000000Z',
      variants: [
        { id: 'v3333333-3333-3333-3333-333333333331', productId: 'p3333333-3333-3333-3333-333333333333', size: '30', color: 'Xám', sku: 'QT-GRY-30', stock: 15 },
      ],
      images: [],
    },
  ];

  carts = new Map<string, Map<string, number>>();
  orders: Order[] = [];
  payments: Payment[] = [];
  inventoryMovements: InventoryMovement[] = [];
  auditLogs: AdminAuditLog[] = [];
  userRoles = new Map<string, 'customer' | 'admin' | 'staff'>();
}

export class InMemoryCategoryRepository implements CategoryRepository {
  constructor(private readonly store: InMemoryStore) {}

  async listAll(): Promise<Category[]> {
    return [...this.store.categories].sort((a, b) => a.sortOrder - b.sortOrder);
  }

  async findById(id: string): Promise<Category | null> {
    return this.store.categories.find((c) => c.id === id) || null;
  }
}

export class InMemoryProductRepository implements ProductRepository {
  constructor(private readonly store: InMemoryStore) {}

  async list(q: ProductQuery): Promise<ProductSummary[]> {
    let filtered = this.store.products.filter((p) => q.includeInactive || p.isActive);
    if (q.categoryId) filtered = filtered.filter((p) => p.categoryId === q.categoryId);
    if (q.minPrice != null) filtered = filtered.filter((p) => p.price >= q.minPrice!);
    if (q.maxPrice != null) filtered = filtered.filter((p) => p.price <= q.maxPrice!);
    if (q.search) {
      filtered = filtered.filter((p) => p.name.toLowerCase().includes(q.search!.toLowerCase()));
    }

    if (q.sort === 'newest') {
      filtered.sort((a, b) => b.createdAt.localeCompare(a.createdAt) || b.id.localeCompare(a.id));
    } else if (q.sort === 'price_asc') {
      filtered.sort((a, b) => a.price - b.price || a.id.localeCompare(b.id));
    } else {
      filtered.sort((a, b) => b.price - a.price || b.id.localeCompare(a.id));
    }

    if (q.cursor) {
      const cursorVal = q.cursor.v;
      const idx = filtered.findIndex((p) => {
        if (q.sort === 'newest') {
          return p.createdAt < String(cursorVal) || (p.createdAt === String(cursorVal) && p.id < q.cursor!.id);
        } else if (q.sort === 'price_asc') {
          return p.price > Number(cursorVal) || (p.price === Number(cursorVal) && p.id > q.cursor!.id);
        } else {
          return p.price < Number(cursorVal) || (p.price === Number(cursorVal) && p.id < q.cursor!.id);
        }
      });
      if (idx !== -1) filtered = filtered.slice(idx);
    }

    return filtered.slice(0, q.limit).map((p) => ({
      id: p.id,
      name: p.name,
      slug: p.slug,
      price: p.price,
      thumbnailUrl: p.thumbnailUrl,
      createdAt: p.createdAt,
    }));
  }

  async findById(id: string): Promise<ProductDetail | null> {
    return this.store.products.find((p) => p.id === id) || null;
  }

  async create(data: Omit<ProductDetail, 'id' | 'createdAt'>): Promise<ProductDetail> {
    const item: ProductDetail = {
      ...data,
      id: `p-${Date.now()}`,
      createdAt: new Date().toISOString(),
    };
    this.store.products.push(item);
    return item;
  }

  async update(id: string, data: Partial<ProductDetail>): Promise<ProductDetail> {
    const idx = this.store.products.findIndex((p) => p.id === id);
    if (idx === -1) throw new AppError('NOT_FOUND', 404, 'Sản phẩm không tồn tại');
    this.store.products[idx] = { ...this.store.products[idx], ...data };
    return this.store.products[idx];
  }
}

export class InMemoryCartRepository implements CartRepository {
  constructor(private readonly store: InMemoryStore) {}

  async getByUserId(userId: string): Promise<Cart> {
    const userCart = this.store.carts.get(userId) || new Map<string, number>();
    const items: CartItem[] = [];

    for (const [variantId, qty] of userCart.entries()) {
      for (const p of this.store.products) {
        const v = p.variants.find((vr) => vr.id === variantId);
        if (v) {
          items.push({
            userId,
            variantId,
            quantity: qty,
            productName: p.name,
            size: v.size,
            color: v.color,
            price: p.price,
            stock: v.stock,
            thumbnailUrl: p.thumbnailUrl,
            updatedAt: new Date().toISOString(),
          });
          break;
        }
      }
    }

    const totalItems = items.reduce((acc, i) => acc + i.quantity, 0);
    const subtotal = items.reduce((acc, i) => acc + i.price * i.quantity, 0);
    return { items, totalItems, subtotal };
  }

  async upsertItem(userId: string, variantId: string, quantity: number): Promise<void> {
    if (!this.store.carts.has(userId)) this.store.carts.set(userId, new Map());
    this.store.carts.get(userId)!.set(variantId, quantity);
  }

  async removeItem(userId: string, variantId: string): Promise<void> {
    this.store.carts.get(userId)?.delete(variantId);
  }
}

export class InMemoryOrderRepository implements OrderRepository {
  constructor(private readonly store: InMemoryStore) {}

  async create(input: CreateOrderInput): Promise<string> {
    if (input.idempotencyKey) {
      const existing = this.store.orders.find(
        (o) => o.userId === input.userId && o.idempotencyKey === input.idempotencyKey
      );
      if (existing) return existing.id;
    }

    let subtotal = 0;
    const orderId = `ord-${Date.now()}`;
    const code = `MS${new Date().toISOString().slice(2, 10).replace(/-/g, '')}${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    const orderItems = input.items.map((item) => {
      let foundVariant = null;
      let parentProduct = null;
      for (const p of this.store.products) {
        const v = p.variants.find((vr) => vr.id === item.variantId);
        if (v) {
          foundVariant = v;
          parentProduct = p;
          break;
        }
      }

      if (!foundVariant || foundVariant.stock < item.quantity) {
        throw new AppError('OUT_OF_STOCK', 409, `OUT_OF_STOCK:${item.variantId}`);
      }

      foundVariant.stock -= item.quantity;
      subtotal += parentProduct!.price * item.quantity;

      return {
        id: `oi-${Date.now()}-${item.variantId}`,
        orderId,
        variantId: item.variantId,
        productName: parentProduct!.name,
        size: foundVariant.size,
        color: foundVariant.color,
        unitPrice: parentProduct!.price,
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
      createdAt: new Date().toISOString(),
      items: orderItems,
    };

    this.store.orders.push(newOrder);
    this.store.carts.delete(input.userId);
    return orderId;
  }

  async findById(id: string): Promise<Order | null> {
    return this.store.orders.find((o) => o.id === id) || null;
  }

  async listByUser(userId: string, limit: number, cursor?: Cursor): Promise<Order[]> {
    let filtered = this.store.orders.filter((o) => o.userId === userId);
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
    let filtered = this.store.orders;
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
    const o = this.store.orders.find((ord) => ord.code === code && ord.shipPhone === phone);
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

export class InMemoryPaymentRepository implements PaymentRepository {
  constructor(private readonly store: InMemoryStore) {}

  async createPending(input: CreatePaymentRecord): Promise<Payment> {
    const p: Payment = {
      id: `pay-${Date.now()}`,
      orderId: input.orderId,
      provider: 'vnpay',
      txnRef: input.txnRef,
      amount: input.amount,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };
    this.store.payments.push(p);
    return p;
  }

  async findByTxnRef(txnRef: string): Promise<Payment | null> {
    return this.store.payments.find((p) => p.txnRef === txnRef) || null;
  }

  async settle(input: SettlePaymentInput): Promise<'ok' | 'already' | 'not_found'> {
    const p = this.store.payments.find((pay) => pay.txnRef === input.txnRef);
    if (!p) return 'not_found';
    if (p.status !== 'pending') return 'already';

    p.status = input.success ? 'success' : 'failed';
    p.paidAt = input.success ? new Date().toISOString() : null;
    p.providerTxnNo = input.txnNo;
    p.bankCode = input.bankCode;
    p.responseCode = input.responseCode;
    p.raw = input.raw;

    if (input.success) {
      const ord = this.store.orders.find((o) => o.id === p.orderId);
      if (ord && ord.status === 'pending_payment') {
        ord.status = 'paid';
      }
    }
    return 'ok';
  }
}

export class InMemoryAdminRepository implements AdminRepository {
  constructor(private readonly store: InMemoryStore) {}

  async adjustStock(
    variantId: string,
    delta: number,
    reason: InventoryMovementReason,
    note?: string,
    adminId?: string
  ): Promise<number> {
    for (const prod of this.store.products) {
      const v = prod.variants.find((vr) => vr.id === variantId);
      if (v) {
        if (v.stock + delta < 0) {
          throw new AppError('INVALID_ADJUSTMENT', 400, 'Tồn kho không thể âm');
        }
        v.stock += delta;
        this.store.inventoryMovements.push({
          id: `inv-${Date.now()}`,
          variantId,
          change: delta,
          reason,
          note,
          createdBy: adminId,
          createdAt: new Date().toISOString(),
        });
        return v.stock;
      }
    }
    throw new AppError('VARIANT_NOT_FOUND', 404, 'Biến thể không tồn tại');
  }

  async updateOrderStatus(
    orderId: string,
    newStatus: OrderStatus,
    _note?: string,
    _adminId?: string
  ): Promise<void> {
    const o = this.store.orders.find((ord) => ord.id === orderId);
    if (!o) throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    if (o.status === 'cancelled') {
      throw new AppError('ORDER_ALREADY_CANCELLED', 400, 'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác');
    }
    o.status = newStatus;
  }

  async setUserRole(userId: string, role: 'customer' | 'admin' | 'staff'): Promise<void> {
    this.store.userRoles.set(userId, role);
  }

  async listInventoryMovements(variantId?: string, limit = 50): Promise<InventoryMovement[]> {
    let list = this.store.inventoryMovements;
    if (variantId) list = list.filter((m) => m.variantId === variantId);
    return list.slice(0, limit);
  }

  async listAuditLogs(limit = 50): Promise<AdminAuditLog[]> {
    return this.store.auditLogs.slice(0, limit);
  }

  async recordAuditLog(
    adminId: string,
    action: string,
    entityType: string,
    entityId?: string,
    before?: unknown,
    after?: unknown
  ): Promise<void> {
    this.store.auditLogs.push({
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
