import { CartRepository } from '../../../domain/repositories/cart.repository.js';

export class RemoveCartItem {
  constructor(private readonly repo: CartRepository) {}

  async execute(userId: string, variantId: string): Promise<void> {
    await this.repo.removeItem(userId, variantId);
  }
}
