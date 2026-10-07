const DEFAULT_API_URL = 'http://localhost:5000';

export function getApiUrl(): string {
  if (typeof window !== 'undefined') {
    return (
      localStorage.getItem('menshop_api_url') ||
      process.env.NEXT_PUBLIC_API_URL ||
      DEFAULT_API_URL
    ).replace(/\/+$/, '');
  }

  return (process.env.NEXT_PUBLIC_API_URL || DEFAULT_API_URL).replace(/\/+$/, '');
}

function getAdminToken(): string {
  const token =
    typeof window !== 'undefined'
      ? localStorage.getItem('menshop_admin_token')?.trim()
      : undefined;

  if (!token) {
    throw new Error('Phiên quản trị đã hết hạn. Vui lòng đăng nhập lại.');
  }

  return token.replace(/^Bearer\s+/i, '');
}

export async function adminFetch<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  headers.set('Accept', 'application/json');
  headers.set('Authorization', `Bearer ${getAdminToken()}`);

  if (options.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  let response: Response;
  try {
    response = await fetch(`${getApiUrl()}${path}`, { ...options, headers });
  } catch {
    throw new Error(
      `Không thể kết nối backend tại ${getApiUrl()}. Hãy kiểm tra backend và URL API trong Cài đặt.`,
    );
  }

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    if (response.status === 401 && typeof window !== 'undefined') {
      localStorage.removeItem('menshop_admin_token');
      localStorage.removeItem('menshop_admin_user');
      if (window.location.pathname !== '/login') {
        window.location.assign('/login');
      }
    }
    const message =
      data?.error?.message || data?.message || `Backend trả về HTTP ${response.status}`;
    throw new Error(message);
  }

  return data as T;
}
