import { IWishlistModel } from '../models/wishlist.model.js';
import { ProductSummary, AppError } from '../models/types.js';

export class WishlistViewModel {
  constructor(private readonly wishlistModel: IWishlistModel) {}

  async getWishlist(userId: string): Promise<ProductSummary[]> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Yêu cầu đăng nhập để xem danh sách yêu thích');
    }
    return this.wishlistModel.getWishlist(userId);
  }

  async add(userId: string, productId: string): Promise<void> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Yêu cầu đăng nhập để thêm vào yêu thích');
    }
    if (!productId) {
      throw new AppError('VALIDATION_ERROR', 400, 'Thiếu mã sản phẩm productId');
    }
    await this.wishlistModel.addToWishlist(userId, productId);
  }

  async remove(userId: string, productId: string): Promise<void> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Yêu cầu đăng nhập để xóa khỏi yêu thích');
    }
    if (!productId) {
      throw new AppError('VALIDATION_ERROR', 400, 'Thiếu mã sản phẩm productId');
    }
    await this.wishlistModel.removeFromWishlist(userId, productId);
  }

  async isFavorite(userId: string, productId: string): Promise<boolean> {
    if (!userId || !productId) return false;
    return this.wishlistModel.isFavorite(userId, productId);
  }
}
