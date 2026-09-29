import type {
  Order,
  OrderStatus,
  Product,
  Category,
  InventoryMovement,
  AuditLog,
  UserAccount,
} from './types';

// ========== CONFIG ==========
export function getApiUrl(): string {
  if (typeof window !== 'undefined') {
    return localStorage.getItem('menshop_api_url') || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';
  }
  return process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';
}

function getAdminToken(): string {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('menshop_admin_token');
    if (token && token.trim()) {
      return token.startsWith('Bearer ') ? token : `Bearer ${token}`;
    }
  }
  throw new Error('Chưa đăng nhập quản trị. Vui lòng đăng nhập lại.');
}

export async function apiFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const BASE = getApiUrl();
  const token = getAdminToken();
  const res = await fetch(`${BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: token,
      ...(options?.headers || {}),
    },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: { message: res.statusText } }));
    if (res.status === 401) {
      throw new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
    throw new Error(err?.error?.message || `HTTP ${res.status}`);
  }
  return res.json();
}

export function extractList<T>(data: unknown): T[] {
  if (Array.isArray(data)) return data as T[];
  const inner = (data as { data?: unknown })?.data;
  if (Array.isArray(inner)) return inner as T[];
  if (inner && typeof inner === 'object') {
    const items = (inner as { items?: unknown }).items;
    if (Array.isArray(items)) return items as T[];
  }
  return [];
}

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
  const data = await apiFetch<unknown>('/api/v1/categories');
  return extractList<Category>(data);
}

// ========== PRODUCTS ==========
export async function fetchAdminProducts(params?: {
  limit?: number;
  page?: number;
  categoryId?: string;
  search?: string;
}): Promise<{ items: Product[]; total: number }> {
  const query = new URLSearchParams();
  if (params?.limit) query.set('limit', String(params.limit));
  if (params?.page) query.set('page', String(params.page));
  if (params?.categoryId) query.set('categoryId', params.categoryId);
  if (params?.search) query.set('q', params.search);

  const qs = query.toString() ? `?${query.toString()}` : '';

  const data = await apiFetch<unknown>(`/api/v1/admin/products${qs}`);
  const items = extractList<Product>(data);
  const total =
    (data as { total?: number })?.total ??
    (data as { pagination?: { total?: number } })?.pagination?.total ??
    items.length;
  return { items, total };
}

export async function fetchProductDetail(id: string): Promise<Product | null> {
  const data = await apiFetch<unknown>(`/api/v1/products/${id}`);
  if (data && typeof data === 'object' && 'id' in data) {
    return data as Product;
  }
  const inner = (data as { data?: Product })?.data;
  return inner ?? null;
}

export async function updateProduct(
  id: string,
  payload: Partial<Product>
): Promise<Product> {
  return await apiFetch<Product>(`/api/v1/admin/products/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

// ========== ORDERS ==========
export async function fetchAdminOrders(
  params?: { status?: string } | OrderStatus | string
): Promise<Order[]> {
  const query = new URLSearchParams();
  if (typeof params === 'string') {
    if (params && params !== 'all') query.set('status', params);
  } else if (params?.status && params.status !== 'all') {
    query.set('status', params.status);
  }
  const qs = query.toString() ? `?${query.toString()}` : '';

  const data = await apiFetch<unknown>(`/api/v1/admin/orders${qs}`);
  const orders = extractList<Order>(data);

  // Normalize shippingAddress from flat fields
  return orders.map((o) => ({
    ...o,
    shippingAddress: o.shippingAddress || {
      name: o.shipName || '',
      phone: o.shipPhone || '',
      address: o.shipAddress || '',
    },
  }));
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
  const data = await apiFetch<unknown>('/api/v1/admin/inventory/movements');
  return extractList<InventoryMovement>(data);
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
  const data = await apiFetch<unknown>('/api/v1/admin/audit-log');
  return extractList<AuditLog>(data);
}

// ========== USERS ==========
export async function fetchAdminUsers(): Promise<UserAccount[]> {
  const data = await apiFetch<unknown>('/api/v1/admin/users');
  return extractList<UserAccount>(data);
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
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data?.error?.message || data?.message || 'Đăng nhập thất bại');
  }
  if (!data.accessToken) {
    throw new Error('Backend không trả về token đăng nhập');
  }
  return {
    user: {
      id: data.user?.id || '',
      email: data.user?.email || normalized,
      fullName: data.user?.fullName || data.user?.full_name || data.user?.name || '',
      role: data.user?.role || 'customer',
    },
    accessToken: data.accessToken,
  };
}

export async function getLockoutStatus(email: string): Promise<unknown> {
  const BASE = getApiUrl();
  const res = await fetch(`${BASE}/api/v1/auth/status?email=${encodeURIComponent(email)}`);
  return res.json();
}
