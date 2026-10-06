import { SupabaseClient } from '@supabase/supabase-js';
import { Review, AppError, Page } from './types.js';

export interface CreateReviewInput {
  userId: string;
  productId: string;
  rating: number;
  comment?: string;
}

export interface IReviewModel {
  createReview(input: CreateReviewInput): Promise<Review>;
  getReviewsByProduct(productId: string, limit: number, page: number): Promise<Page<Review>>;
  getAllReviews(limit: number, page: number): Promise<Page<Review>>;
  deleteReview(reviewId: string, userId?: string, isAdmin?: boolean): Promise<void>;
  canUserReview(userId: string, productId: string): Promise<boolean>;
}

export class ReviewModel implements IReviewModel {
  private inMemoryReviews: Review[] = [
    {
      id: 'rev-001',
      userId: '7fb74d58-4155-4ab5-8124-cb0b5bb6651d',
      productId: 'prod-001',
      rating: 5,
      comment: 'Áo chất liệu cotton thoáng mát, form dáng rất đẹp!',
      createdAt: new Date().toISOString(),
      user: {
        id: '7fb74d58-4155-4ab5-8124-cb0b5bb6651d',
        email: 'customer@gmail.com',
        name: 'Nguyễn Văn Khách',
      },
    },
    {
      id: 'rev-002',
      userId: 'usr-admin-001',
      productId: 'prod-001',
      rating: 4,
      comment: 'Giao hàng nhanh, đóng gói cẩn thận. Rất ưng ý.',
      createdAt: new Date().toISOString(),
      user: {
        id: 'usr-admin-001',
        email: 'admin@gmail.com',
        name: 'Admin MenShop',
      },
    },
  ];

  constructor(private readonly supabase?: SupabaseClient) {}

  async createReview(input: CreateReviewInput): Promise<Review> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('reviews')
        .insert({
          user_id: input.userId,
          product_id: input.productId,
          rating: input.rating,
          comment: input.comment || null,
        })
        .select('*, user:profiles(id, email, full_name)')
        .single();

      if (error) {
        if (error.code === '23505') {
          throw new AppError('REVIEW_ALREADY_EXISTS', 409, 'Bạn đã đánh giá sản phẩm này rồi');
        }
        throw new AppError('DB_CREATE_REVIEW_FAILED', 500, error.message);
      }

      return this.mapToReview(data);
    }

    // In-memory mock
    const exists = this.inMemoryReviews.some(
      (r) => r.userId === input.userId && r.productId === input.productId
    );
    if (exists) {
      throw new AppError('REVIEW_ALREADY_EXISTS', 409, 'Bạn đã đánh giá sản phẩm này rồi');
    }

    const newRev: Review = {
      id: `rev-${Date.now()}`,
      userId: input.userId,
      productId: input.productId,
      rating: input.rating,
      comment: input.comment || null,
      createdAt: new Date().toISOString(),
      user: {
        id: input.userId,
        email: 'user@gmail.com',
        name: 'Người dùng Menly',
      },
    };
    this.inMemoryReviews.unshift(newRev);
    return newRev;
  }

  async getReviewsByProduct(productId: string, limit: number = 10, page: number = 1): Promise<Page<Review>> {
    if (this.supabase) {
      const from = (page - 1) * limit;
      const to = from + limit - 1;

      const { data, error, count } = await this.supabase
        .from('reviews')
        .select('*, user:profiles(id, email, full_name)', { count: 'exact' })
        .eq('product_id', productId)
        .order('created_at', { ascending: false })
        .range(from, to);

      if (error) throw new AppError('DB_GET_REVIEWS_FAILED', 500, error.message);

      const items = (data || []).map(this.mapToReview);
      return {
        items,
        pageInfo: {
          limit,
          hasNext: count !== null && from + limit < count,
          nextCursor: (page + 1).toString(),
        },
      };
    }

    const filtered = this.inMemoryReviews.filter((r) => r.productId === productId);
    const start = (page - 1) * limit;
    const items = filtered.slice(start, start + limit);
    return {
      items,
      pageInfo: {
        limit,
        hasNext: start + limit < filtered.length,
        nextCursor: (page + 1).toString(),
      },
    };
  }

  async getAllReviews(limit: number = 20, page: number = 1): Promise<Page<Review>> {
    if (this.supabase) {
      const from = (page - 1) * limit;
      const to = from + limit - 1;

      const { data, error, count } = await this.supabase
        .from('reviews')
        .select('*, user:profiles(id, email, full_name)', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to);

      if (error) throw new AppError('DB_GET_ALL_REVIEWS_FAILED', 500, error.message);

      const items = (data || []).map(this.mapToReview);
      return {
        items,
        pageInfo: {
          limit,
          hasNext: count !== null && from + limit < count,
          nextCursor: (page + 1).toString(),
        },
      };
    }

    const start = (page - 1) * limit;
    const items = this.inMemoryReviews.slice(start, start + limit);
    return {
      items,
      pageInfo: {
        limit,
        hasNext: start + limit < this.inMemoryReviews.length,
        nextCursor: (page + 1).toString(),
      },
    };
  }

  async deleteReview(reviewId: string, userId?: string, isAdmin?: boolean): Promise<void> {
    if (this.supabase) {
      let query = this.supabase.from('reviews').delete().eq('id', reviewId);
      if (!isAdmin && userId) {
        query = query.eq('user_id', userId);
      }
      const { error } = await query;
      if (error) throw new AppError('DB_DELETE_REVIEW_FAILED', 500, error.message);
      return;
    }

    const idx = this.inMemoryReviews.findIndex(
      (r) => r.id === reviewId && (isAdmin || !userId || r.userId === userId)
    );
    if (idx !== -1) {
      this.inMemoryReviews.splice(idx, 1);
    }
  }

  async canUserReview(userId: string, productId: string): Promise<boolean> {
    if (this.supabase) {
      // A user can review if they have at least one completed order containing the product
      const { data: orders } = await this.supabase
        .from('orders')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'completed');
        
      if (!orders || orders.length === 0) return false;
      const orderIds = orders.map((o) => o.id);

      const { data: items } = await this.supabase
        .from('order_items')
        .select('variant:product_variants!inner(product_id)')
        .in('order_id', orderIds)
        .eq('variant.product_id', productId)
        .limit(1);

      return items ? items.length > 0 : false;
    }

    return true;
  }

  private mapToReview(row: any): Review {
    const userObj = row.user || row.profiles;
    return {
      id: row.id,
      userId: row.user_id,
      productId: row.product_id,
      rating: row.rating,
      comment: row.comment,
      createdAt: row.created_at,
      user: userObj ? {
        id: userObj.id,
        email: userObj.email,
        name: userObj.full_name || userObj.name || userObj.email,
      } : undefined,
    };
  }
}
