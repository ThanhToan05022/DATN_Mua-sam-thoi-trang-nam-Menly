import type {
  Order,
  OrderStatus,
  Product,
  Category,
  InventoryMovement,
  AuditLog,
  UserAccount,
  Voucher,
  CreateVoucherInput,
} from './types';

import { adminFetch as apiFetch, getApiUrl } from './api-client';

// ========== HEALTH ==========
export async function checkServerHealth(): Promise<boolean> {
  try {
    const BASE = getApiUrl();
    const res = await fetch(`${BASE}/health`, { method: 'GET' });
    return res.ok;
  } catch {
    return false;
  }
}

// ========== CATEGORIES ==========
export async function fetchCategories(): Promise<Category[]> {
  const data = await apiFetch<Category[] | { data?: Category[]; items?: Category[] }>(
    '/api/v1/categories',
  );
  if (Array.isArray(data)) return data;
  return data.data || data.items || [];
}

// ========== PRODUCTS ==========
export async function fetchAdminProducts(params?: {
  limit?: number;
  page?: number;
  categoryId?: string;
  search?: string;
}): Promise<{ items: Product[]; total: number }> {
  const query = new URLSearchParams();
  const effectiveLimit = params?.limit || 400;
  query.set('limit', String(effectiveLimit));
  if (params?.categoryId) query.set('categoryId', params.categoryId);
  if (params?.search) {
    query.set('q', params.search);
  }

  const qs = query.toString() ? `?${query.toString()}` : '';

  const data = await apiFetch<
    { items?: Product[]; data?: Product[]; total?: number; pageInfo?: { total?: number } } | Product[]
  >(`/api/v1/admin/products${qs}`);
  if (Array.isArray(data)) return { items: data, total: data.length };

  const items = data.items || data.data || [];
  return { items, total: data.total ?? data.pageInfo?.total ?? items.length };
}

export async function fetchProductDetail(id: string): Promise<Product | null> {
  const data = await apiFetch<{ data?: Product } | Product>(`/api/v1/admin/products/${id}`);
  if (data && 'data' in data && data.data) return data.data;
  return data && 'id' in data ? data : null;
}

export async function updateProduct(
  id: string,
  payload: Partial<Product>
): Promise<Product> {
  return apiFetch<Product>(`/api/v1/admin/products/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export async function deleteProduct(id: string): Promise<void> {
  await apiFetch<{ message: string }>(`/api/v1/admin/products/${id}`, {
    method: 'DELETE',
  });
}

export interface CreateProductInput {
  categoryId: string;
  name: string;
  description: string | null;
  price: number;
  thumbnailUrl: string | null;
  images: string[];
  isActive: boolean;
  variants: Array<{
    size: string;
    color: string;
    sku: string;
    stock: number;
  }>;
}

export async function createAdminProduct(payload: CreateProductInput): Promise<Product> {
  return apiFetch<Product>('/api/v1/admin/products', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

// ========== ORDERS ==========
export async function fetchAdminOrders(
  params?: { status?: string } | OrderStatus | string
): Promise<Order[]> {
  const statusFilter =
    typeof params === 'string'
      ? params === 'all'
        ? undefined
        : params
      : params?.status === 'all'
      ? undefined
      : params?.status;

  try {
    const query = new URLSearchParams();
    if (statusFilter) query.set('status', statusFilter);
    const qs = query.toString() ? `?${query.toString()}` : '';

    const data = await apiFetch<any>(`/api/v1/admin/orders${qs}`);

    let rawList: any[] = [];
    if (Array.isArray(data)) {
      rawList = data;
    } else if (data && Array.isArray(data.items)) {
      rawList = data.items;
    } else if (data && Array.isArray(data.data)) {
      rawList = data.data;
    }

    return rawList.map((o: any) => ({
      id: o.id || `ord-${Math.random()}`,
      code: o.code || 'MS000',
      userId: o.userId || o.user_id || '',
      status: (o.status || 'pending_payment') as OrderStatus,
      paymentMethod: o.paymentMethod || o.payment_method || 'cod',
      subtotal: Number(o.subtotal || 0),
      shippingFee: Number(o.shippingFee || o.shipping_fee || 0),
      total: Number(o.total || 0),
      shipName: o.shipName || o.ship_name || o.ship?.name || '',
      shipPhone: o.shipPhone || o.ship_phone || o.ship?.phone || '',
      shipAddress: o.shipAddress || o.ship_address || o.ship?.address || '',
      shippingAddress: o.shippingAddress || {
        name: o.shipName || o.ship_name || o.ship?.name || '',
        phone: o.shipPhone || o.ship_phone || o.ship?.phone || '',
        address: o.shipAddress || o.ship_address || o.ship?.address || '',
        note: o.note || '',
      },
      createdAt: o.createdAt || o.created_at || new Date().toISOString(),
      items: (o.items || o.order_items || []).map((it: any) => ({
        id: it.id || `oi-${Math.random()}`,
        orderId: it.orderId || it.order_id || o.id,
        variantId: it.variantId || it.variant_id || '',
        productName: it.productName || it.product_name || 'Sản phẩm',
        size: it.size || 'M',
        color: it.color || 'Trắng',
        unitPrice: Number(it.unitPrice ?? it.unit_price ?? it.price ?? 0),
        quantity: Number(it.quantity || 1),
      })),
    }));
  } catch (err) {
    console.warn('Backend orders fetch notice:', err);
    return [];
  }
}

export async function updateOrderStatus(
  orderId: string,
  status: OrderStatus,
  note?: string
): Promise<void> {
  await apiFetch(`/api/v1/admin/orders/${orderId}/status`, {
    method: 'PUT',
    body: JSON.stringify({ status, note: note || '' }),
  });
}

// ========== INVENTORY ==========
export async function fetchInventoryMovements(): Promise<InventoryMovement[]> {
  try {
    const data = await apiFetch<{ data: InventoryMovement[] } | InventoryMovement[]>(
      '/api/v1/admin/inventory/movements'
    );
    if (Array.isArray(data)) return data;
    return (data as { data: InventoryMovement[] }).data || [];
  } catch {
    return [];
  }
}

export async function adjustInventory(
  variantIdOrParams: string | { variantId: string; change?: number; delta?: number; reason: string; note?: string },
  changeOrDelta?: number,
  reason?: string,
  note?: string
): Promise<void> {
  let bodyPayload: { variantId: string; delta: number; reason: string; note?: string };
  if (typeof variantIdOrParams === 'string') {
    bodyPayload = {
      variantId: variantIdOrParams,
      delta: changeOrDelta ?? 0,
      reason: reason || 'admin_restock',
      note: note || '',
    };
  } else {
    bodyPayload = {
      variantId: variantIdOrParams.variantId,
      delta: variantIdOrParams.delta ?? variantIdOrParams.change ?? 0,
      reason: variantIdOrParams.reason || 'admin_restock',
      note: variantIdOrParams.note || '',
    };
  }
  await apiFetch('/api/v1/admin/inventory/adjust', {
    method: 'POST',
    body: JSON.stringify(bodyPayload),
  });
}

// ========== AUDIT LOGS ==========
export async function fetchAuditLogs(): Promise<AuditLog[]> {
  const data = await apiFetch<{ data: AuditLog[] } | AuditLog[]>('/api/v1/admin/audit-log');
  if (Array.isArray(data)) return data;
  return (data as { data: AuditLog[] }).data || [];
}

// ========== USERS ==========
export async function fetchAdminUsers(): Promise<UserAccount[]> {
  const data = await apiFetch<{ data?: UserAccount[] } | UserAccount[]>('/api/v1/admin/users');
  return Array.isArray(data) ? data : data.data || [];
}

export async function updateUserRole(userId: string, role: 'admin' | 'customer'): Promise<void> {
  await apiFetch(`/api/v1/admin/users/${userId}/role`, {
    method: 'PUT',
    body: JSON.stringify({ role }),
  });
}

// ========== AUTH ==========
export interface AuthSession {
  user: {
    id: string;
    email: string;
    fullName?: string;
    role: string;
    accessToken?: string;
  };
  accessToken: string;
}

export async function loginUser(email: string, password: string): Promise<AuthSession> {
  const BASE = getApiUrl();
  const normalized = email.toLowerCase().trim();

  const res = await fetch(`${BASE}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: normalized, password }),
  }).catch(() => {
    throw new Error(`Không thể kết nối backend tại ${BASE}. Hãy khởi động backend rồi thử lại.`);
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data?.error?.message || data?.message || 'Đăng nhập thất bại');
  }
  if (!data.accessToken || !data.user?.id || !data.user?.role) {
    throw new Error('Backend trả về phiên đăng nhập không hợp lệ.');
  }
  return {
    user: {
      id: data.user.id,
      email: data.user?.email || normalized,
      fullName: data.user?.fullName || data.user?.full_name || data.user?.name || 'Admin MenShop',
      role: data.user.role,
    },
    accessToken: data.accessToken,
  };
}

export async function getLockoutStatus(email: string): Promise<unknown> {
  const BASE = getApiUrl();
  const res = await fetch(`${BASE}/api/v1/auth/status?email=${encodeURIComponent(email)}`);
  return res.json();
}

// ========== VOUCHERS ==========
export async function fetchAdminVouchers(): Promise<Voucher[]> {
  const data = await apiFetch<Voucher[] | { data?: Voucher[] }>('/api/v1/admin/vouchers');
  return Array.isArray(data) ? data : data.data || [];
}

export async function createVoucher(data: CreateVoucherInput): Promise<Voucher> {
  return apiFetch<Voucher>('/api/v1/admin/vouchers', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function updateVoucher(id: string, data: Partial<CreateVoucherInput>): Promise<Voucher> {
  return apiFetch<Voucher>(`/api/v1/admin/vouchers/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

export async function deleteVoucher(id: string): Promise<boolean> {
  return apiFetch<{ success: boolean }>(`/api/v1/admin/vouchers/${id}`, {
    method: 'DELETE',
  }).then((r) => r.success);
}

