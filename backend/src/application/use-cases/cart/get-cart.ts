import { Cart } from '../../../domain/entities/cart.js';
import { CartRepository } from '../../../domain/repositories/cart.repository.js';

export class GetCart {
  constructor(private readonly repo: CartRepository) {}

  async execute(userId: string): Promise<Cart> {
    return this.repo.getByUserId(userId);
  }
}
