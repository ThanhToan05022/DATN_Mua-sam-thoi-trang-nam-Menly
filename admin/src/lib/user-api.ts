import type { UserAccount } from './types';
import type { AuthSession } from './api';
import { INITIAL_USERS } from './mock-admin-data';

// ========== CONFIG ==========
function getApiUrl(): string {
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
  return 'Bearer mock-admin-123';
}

async function adminFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const BASE = getApiUrl();
  const token = getAdminToken();
  try {
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
      throw new Error(err?.error?.message || `HTTP ${res.status}`);
    }
    return res.json();
  } catch (err: any) {
    if (err.name === 'TypeError' && (err.message.includes('fetch') || err.message.includes('Failed to fetch'))) {
      throw new Error(`Không thể kết nối đến máy chủ Backend (${BASE}). Vui lòng đảm bảo Backend đang chạy tại cổng 5000.`);
    }
    throw err;
  }
}

// ========== AUTH ==========
export async function registerUser(
  name: string,
  email: string,
  password: string,
  _role?: string
): Promise<AuthSession> {
  const BASE = getApiUrl();
  const res = await fetch(`${BASE}/api/v1/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, email, password }),
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data?.error?.message || 'Đăng ký thất bại');
  }
  return {
    user: {
      id: data.user?.id || '',
      email: data.user?.email || email,
      fullName: data.user?.fullName || name,
      role: data.user?.role || 'customer',
    },
    accessToken: data.accessToken || '',
  };
}

// ========== ADMIN USER MANAGEMENT ==========
export async function fetchAdminUsers(): Promise<UserAccount[]> {
  try {
    const data = await adminFetch<{ data?: UserAccount[] } | UserAccount[]>('/api/v1/admin/users');
    const list = Array.isArray(data) ? data : (data as { data?: UserAccount[] })?.data;
    if (Array.isArray(list) && list.length > 0) {
      const map = new Map<string, UserAccount>();
      for (const u of list) {
        if (u && (u.id || u.email)) {
          map.set((u.email || u.id).toLowerCase(), u);
        }
      }
      for (const def of INITIAL_USERS) {
        const key = (def.email || def.id).toLowerCase();
        if (!map.has(key)) {
          map.set(key, def);
        }
      }
      return Array.from(map.values());
    }
  } catch (err) {
    console.warn('fetchAdminUsers API call failed, falling back to INITIAL_USERS:', err);
  }
  return INITIAL_USERS;
}

export async function createAdminUser(payload: {
  name: string;
  email: string;
  password?: string;
  role?: string;
}): Promise<UserAccount> {
  const data = await adminFetch<{ data?: UserAccount } | UserAccount>('/api/v1/admin/users', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if ('data' in (data as object) && (data as { data?: UserAccount }).data) {
    return (data as { data: UserAccount }).data;
  }
  return data as UserAccount;
}

export async function updateAdminUser(
  id: string,
  payload: Partial<{ name: string; email: string; role: string }>
): Promise<UserAccount> {
  const data = await adminFetch<{ data?: UserAccount } | UserAccount>(`/api/v1/admin/users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
  if ('data' in (data as object) && (data as { data?: UserAccount }).data) {
    return (data as { data: UserAccount }).data;
  }
  return data as UserAccount;
}

export async function deleteAdminUser(id: string): Promise<void> {
  await adminFetch(`/api/v1/admin/users/${id}`, { method: 'DELETE' });
}

export async function toggleLockAdminUser(id: string, isLocked: boolean): Promise<UserAccount> {
  const data = await adminFetch<{ user?: UserAccount } | UserAccount>(
    `/api/v1/admin/users/${id}/lock`,
    {
      method: 'PATCH',
      body: JSON.stringify({ isLocked }),
    }
  );
  if ('user' in (data as object) && (data as { user?: UserAccount }).user) {
    return (data as { user: UserAccount }).user;
  }
  return data as UserAccount;
}
