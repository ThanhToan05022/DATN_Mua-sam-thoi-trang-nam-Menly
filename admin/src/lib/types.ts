// ========== ORDER TYPES ==========
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

export interface ShippingAddress {
  name: string;
  phone: string;
  address: string;
  note?: string;
}

export interface Order {
  id: string;
  code: string;
  userId: string;
  status: OrderStatus;
  paymentMethod: 'cod' | 'vnpay';
  subtotal: number;
  shippingFee: number;
  total: number;
  shipName: string;
  shipPhone: string;
  shipAddress: string;
  shippingAddress: ShippingAddress;
  createdAt: string;
  items: OrderItem[];
}

// ========== PRODUCT TYPES ==========
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

export interface Product {
  id: string;
  categoryId: string;
  name: string;
  slug: string;
  description: string | null;
  price: number;
  thumbnailUrl: string | null;
  isActive: boolean;
  createdAt: string;
  variants?: ProductVariant[];
  images?: ProductImage[];
}

// ========== CATEGORY TYPES ==========
export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string | null;
  imageUrl?: string | null;
  sortOrder?: number;
}

// ========== INVENTORY TYPES ==========
export type InventoryMovementReason =
  | 'order_created'
  | 'order_cancelled'
  | 'admin_restock'
  | 'admin_correction';

export interface InventoryMovement {
  id: string;
  variantId: string;
  productName?: string;
  sku?: string;
  change?: number;
  delta: number;
  reason: InventoryMovementReason;
  orderId?: string | null;
  createdBy?: string | null;
  actorId?: string | null;
  note?: string | null;
  createdAt: string;
}

// ========== AUDIT LOG TYPES ==========
export interface AuditLog {
  id: string;
  adminId?: string;
  actorId?: string;
  action: string;
  entityType?: string;
  entity?: string;
  entityId?: string | null;
  metadata?: unknown;
  before?: unknown;
  after?: unknown;
  createdAt: string;
}

// ========== USER ACCOUNT TYPES ==========
export interface UserAccount {
  id: string;
  email: string;
  name?: string;
  fullName?: string | null;
  role: 'customer' | 'admin' | 'guest' | 'user' | 'seller';
  createdAt: string;
  phone?: string | null;
  avatarUrl?: string | null;
  isLocked?: boolean;
  isActive?: boolean;
}

