export interface Review {
  id: string;
  userId: string;
  productId: string;
  rating: number;
  comment: string | null;
  createdAt: string;
  user?: {
    id: string;
    email: string;
    name: string;
  };
}

export interface ReviewPageResult {
  items: Review[];
  pageInfo?: {
    limit: number;
    hasNext: boolean;
    nextCursor: string | null;
  };
}

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
      throw new Error(`Không thể kết nối đến máy chủ Backend (${BASE}). Vui lòng đảm bảo Backend đang chạy.`);
    }
    throw err;
  }
}

export async function fetchAdminReviews(page: number = 1, limit: number = 50): Promise<ReviewPageResult> {
  const data = await adminFetch<ReviewPageResult | { data?: ReviewPageResult }>(
    `/api/v1/admin/reviews?page=${page}&limit=${limit}`
  );
  if ('items' in data) return data;
  if ('data' in data && data.data) return data.data;
  return { items: [] };
}

export async function deleteAdminReview(id: string): Promise<void> {
  await adminFetch(`/api/v1/admin/reviews/${id}`, {
    method: 'DELETE',
  });
}
