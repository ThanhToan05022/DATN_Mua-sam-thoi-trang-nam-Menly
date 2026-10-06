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
  constructor(private readonly supabase?: SupabaseClient) {}

  async createReview(input: CreateReviewInput): Promise<Review> {
    if (!this.supabase) {
      throw new AppError('SUPABASE_NOT_INITIALIZED', 500, 'Supabase client is required');
    }

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

  async getReviewsByProduct(productId: string, limit: number, page: number): Promise<Page<Review>> {
    if (!this.supabase) return { items: [], pageInfo: { limit, hasNext: false, nextCursor: null } };

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

  async getAllReviews(limit: number, page: number): Promise<Page<Review>> {
    if (!this.supabase) return { items: [], pageInfo: { limit, hasNext: false, nextCursor: null } };

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

  async deleteReview(reviewId: string, userId?: string, isAdmin?: boolean): Promise<void> {
    if (!this.supabase) return;

    let query = this.supabase.from('reviews').delete().eq('id', reviewId);
    
    if (!isAdmin && userId) {
      query = query.eq('user_id', userId);
    }

    const { error, count } = await query;
    if (error) throw new AppError('DB_DELETE_REVIEW_FAILED', 500, error.message);
  }

  async canUserReview(userId: string, productId: string): Promise<boolean> {
    if (!this.supabase) return false;

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
