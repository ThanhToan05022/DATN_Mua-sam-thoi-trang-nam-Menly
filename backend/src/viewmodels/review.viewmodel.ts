import { Review, Page, AppError } from '../models/types.js';
import { IReviewModel } from '../models/review.model.js';
import { z } from 'zod';

const createReviewSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(1000).optional(),
});

export class ReviewViewModel {
  constructor(private readonly reviewModel: IReviewModel) {}

  async createReview(userId: string, productId: string, payload: any): Promise<Review> {
    const validated = createReviewSchema.parse(payload);
    
    const canReview = await this.reviewModel.canUserReview(userId, productId);
    if (!canReview) {
      throw new AppError('CANNOT_REVIEW', 403, 'Bạn chỉ có thể đánh giá sản phẩm sau khi đã mua và nhận hàng thành công.');
    }

    return this.reviewModel.createReview({
      userId,
      productId,
      rating: validated.rating,
      comment: validated.comment,
    });
  }

  async getProductReviews(productId: string, limit: number = 10, page: number = 1): Promise<Page<Review>> {
    return this.reviewModel.getReviewsByProduct(productId, limit, page);
  }

  async deleteReview(reviewId: string, userId: string): Promise<void> {
    await this.reviewModel.deleteReview(reviewId, userId, false);
  }

  async getAdminReviews(limit: number = 20, page: number = 1): Promise<Page<Review>> {
    return this.reviewModel.getAllReviews(limit, page);
  }

  async adminDeleteReview(reviewId: string, adminId: string): Promise<void> {
    await this.reviewModel.deleteReview(reviewId, undefined, true);
  }
}
