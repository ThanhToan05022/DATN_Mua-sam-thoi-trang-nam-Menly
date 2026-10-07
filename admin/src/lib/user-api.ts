import type { UserAccount } from './types';
import type { AuthSession } from './api';
import { adminFetch, getApiUrl } from './api-client';

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
  const data = await adminFetch<{ data?: UserAccount[] } | UserAccount[]>('/api/v1/admin/users');
  return Array.isArray(data) ? data : data.data || [];
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
