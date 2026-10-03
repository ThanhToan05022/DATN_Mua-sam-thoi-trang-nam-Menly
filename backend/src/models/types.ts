export class AppError<T = Record<string, any>> extends Error {
  constructor(
    public readonly code: string,
    public readonly status: number = 400,
    message?: string,
    public readonly details?: T
  ) {
    super(message || code);
    this.name = 'AppError';
  }
}

export class InfraError extends Error {
  constructor(
    public readonly code: string,
    public readonly cause?: unknown,
    message?: string
  ) {
    super(message || code);
    this.name = 'InfraError';
  }
}

export type Cursor = {
  v: number | string;
  id: string;
};

export interface PageInfo {
  limit: number;
  hasNext: boolean;
  nextCursor: string | null;
}

export interface Page<T> {
  items: T[];
  pageInfo: PageInfo;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  sortOrder: number;
}

export interface ProductSummary {
  id: string;
  categoryId?: string;
  name: string;
  slug: string;
  price: number;
  thumbnailUrl: string | null;
  createdAt: string;
  variants?: ProductVariant[];
}

export interface ProductVariant {
  id: string;
  productId: string;
  size: string;
  color: string;
  sku: string;
  stock: number;
}

export interface ProductImage {
  id: string;
  productId: string;
  url: string;
  sortOrder: number;
}

export interface ProductDetail {
  id: string;
  categoryId: string;
  name: string;
  slug: string;
  description: string | null;
  price: number;
  thumbnailUrl: string | null;
  isActive: boolean;
  createdAt: string;
  variants: ProductVariant[];
  images: ProductImage[];
}

export interface CartItem {
  userId: string;
  variantId: string;
  quantity: number;
  productName: string;
  size: string;
  color: string;
  price: number;
  stock: number;
  thumbnailUrl: string | null;
  updatedAt: string;
}

export interface Cart {
  items: CartItem[];
  totalItems: number;
  subtotal: number;
}

export type OrderStatus =
  | 'pending_payment'
  | 'paid'
  | 'processing'
  | 'shipping'
  | 'completed'
  | 'cancelled';

export interface OrderItem {
  id: string;
  orderId: string;
  variantId: string;
  productName: string;
  size: string;
  color: string;
  unitPrice: number;
  quantity: number;
}

export interface ShippingInfo {
  name: string;
  phone: string;
  address: string;
}

export interface UserAddress {
  id: string;
  userId: string;
  recipientName: string;
  phone: string;
  province: string;
  district: string;
  ward: string;
  detailAddress: string;
  isDefault: boolean;
  createdAt: string;
}

export interface CreateAddressInput {
  recipientName: string;
  phone: string;
  province: string;
  district: string;
  ward: string;
  detailAddress: string;
  isDefault?: boolean;
}

export type UpdateAddressInput = Partial<CreateAddressInput>;

/** Một mốc trong dòng thời gian trạng thái đơn hàng */
export interface OrderStatusHistoryEntry {
  status: OrderStatus;
  note?: string | null;
  changedBy?: string | null;
  createdAt: string;
}

/** Một bước trên timeline hiển thị cho người dùng */
export interface OrderTimelineStep {
  status: OrderStatus;
  label: string;
  description: string;
  createdAt: string | null;
  /** Ghi chú kèm theo mốc (ví dụ lý do huỷ, ghi chú admin) */
  note?: string | null;
  completed: boolean;
  current: boolean;
}

export interface Order {
  id: string;
  code: string;
  userId: string;
  userEmail?: string;
  status: OrderStatus;
  paymentMethod: 'cod' | 'vnpay';
  subtotal: number;
  shippingFee: number;
  total: number;
  shipName: string;
  shipPhone: string;
  shipAddress: string;
  note?: string;
  idempotencyKey?: string | null;
  expiresAt?: string | null;
  voucherCode?: string | null;
  discountAmount?: number;
  createdAt: string;
  items?: OrderItem[];
  statusHistory?: OrderStatusHistoryEntry[];
  timeline?: OrderTimelineStep[];
}

export type PaymentStatus = 'pending' | 'success' | 'failed';

export interface Payment {
  id: string;
  orderId: string;
  provider: 'vnpay';
  txnRef: string;
  amount: number;
  status: PaymentStatus;
  providerTxnNo?: string | null;
  bankCode?: string | null;
  responseCode?: string | null;
  raw?: unknown;
  createdAt: string;
  paidAt?: string | null;
}

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

export type DiscountType = 'percentage' | 'fixed_amount';

export interface Voucher {
  id: string;
  code: string;
  title: string;
  discountType: DiscountType;
  discountValue: number;
  minOrderValue: number;
  maxDiscount?: number | null;
  usageLimit: number;
  usedCount: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
  createdAt?: string;
}
