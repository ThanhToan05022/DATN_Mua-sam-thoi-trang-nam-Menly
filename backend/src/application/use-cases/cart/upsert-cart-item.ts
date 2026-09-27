import { CartRepository } from '../../../domain/repositories/cart.repository.js';
import { AppError } from '../../../domain/errors.js';

export interface UpsertCartItemInput {
  userId: string;
  variantId: string;
  quantity: number;
}

export class UpsertCartItem {
  constructor(private readonly repo: CartRepository) {}

  async execute(i: UpsertCartItemInput): Promise<void> {
    if (i.quantity < 0 || i.quantity > 20) {
      throw new AppError('INVALID_QUANTITY', 400, 'Số lượng phải từ 0 đến 20');
    }

    if (i.quantity === 0) {
      await this.repo.removeItem(i.userId, i.variantId);
    } else {
      await this.repo.upsertItem(i.userId, i.variantId, i.quantity);
    }
  }
}
