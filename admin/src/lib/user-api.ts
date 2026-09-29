import type { UserAccount } from './types';
import type { AuthSession } from './api';
import { apiFetch, extractList, getApiUrl } from './api';

// ========== AUTH ==========
// Backend hien tai chi tao tai khoan khach hang, tham so role duoc giu lai de
// tuong thich voi API cu, nhung khong gui len server.
export async function registerUser(
  name: string,
  email: string,
  password: string
): Promise<AuthSession> {
  const BASE = getApiUrl();
  const res = await fetch(`${BASE}/api/v1/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, email, password }),
  });
  const data = await res.json().catch(() => ({}));
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
  return extractList<UserAccount>(await apiFetch<unknown>('/api/v1/admin/users'));
}

export async function createAdminUser(payload: {
  name: string;
  email: string;
  password?: string;
  role?: string;
}): Promise<UserAccount> {
  return (await apiFetch<UserAccount>('/api/v1/admin/users', {
    method: 'POST',
    body: JSON.stringify(payload),
  })) as UserAccount;
}

export async function updateAdminUser(
  id: string,
  payload: Partial<{ name: string; email: string; role: string }>
): Promise<UserAccount> {
  return (await apiFetch<UserAccount>(`/api/v1/admin/users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  })) as UserAccount;
}

export async function deleteAdminUser(id: string): Promise<void> {
  await apiFetch(`/api/v1/admin/users/${id}`, { method: 'DELETE' });
}

export async function toggleLockAdminUser(id: string, isLocked: boolean): Promise<UserAccount> {
  const data = await apiFetch<{ user?: UserAccount }>(`/api/v1/admin/users/${id}/lock`, {
    method: 'PATCH',
    body: JSON.stringify({ isLocked }),
  });
  return data.user ?? (data as unknown as UserAccount);
}
