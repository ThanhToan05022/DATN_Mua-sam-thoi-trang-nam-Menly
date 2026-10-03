import { Cart } from '../entities/cart.js';

export interface CartRepository {
  getByUserId(userId: string): Promise<Cart>;
  upsertItem(userId: string, variantId: string, quantity: number): Promise<void>;
  removeItem(userId: string, variantId: string): Promise<void>;
}
