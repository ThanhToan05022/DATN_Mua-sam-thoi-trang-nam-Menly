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
import { adminFetch } from './api-client';

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
