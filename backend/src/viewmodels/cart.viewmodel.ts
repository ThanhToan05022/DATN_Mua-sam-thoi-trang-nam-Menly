import { Cart, AppError } from '../models/types.js';
import { ICartModel } from '../models/cart.model.js';

export class CartViewModel {
  constructor(private readonly model: ICartModel) {}

  async getCart(userId: string): Promise<Cart> {
    return this.model.getByUserId(userId);
  }

  async updateItem(userId: string, variantId: string, quantity: number): Promise<Cart> {
    if (quantity < 0 || quantity > 20) {
      throw new AppError('INVALID_QUANTITY', 400, 'Số lượng phải từ 0 đến 20');
    }

    if (quantity === 0) {
      await this.model.removeItem(userId, variantId);
    } else {
      await this.model.upsertItem(userId, variantId, quantity);
    }

    return this.model.getByUserId(userId);
  }

  async removeItem(userId: string, variantId: string): Promise<Cart> {
    await this.model.removeItem(userId, variantId);
    return this.model.getByUserId(userId);
  }
}
