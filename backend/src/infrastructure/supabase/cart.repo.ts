import { SupabaseClient } from '@supabase/supabase-js';
import { Cart, CartItem } from '../../domain/entities/cart.js';
import { CartRepository } from '../../domain/repositories/cart.repository.js';
import { InfraError } from '../../domain/errors.js';

export class SupabaseCartRepository implements CartRepository {
  constructor(private readonly db: SupabaseClient) {}

  async getByUserId(userId: string): Promise<Cart> {
    const { data, error } = await this.db
      .from('cart_items')
      .select(`
        user_id, variant_id, quantity, updated_at,
        variant:product_variants (
          id, size, color, stock,
          product:products (
            name, price, thumbnail_url
          )
        )
      `)
      .eq('user_id', userId);

    if (error) {
      throw new InfraError('DB_CART_QUERY_FAILED', error);
    }

    type RawCartRow = {
      user_id: string;
      variant_id: string;
      quantity: number;
      updated_at: string;
      variant?: {
        id: string;
        size: string;
        color: string;
        stock: number;
        product?: {
          name: string;
          price: number;
          thumbnail_url: string | null;
        };
      };
    };

    const items: CartItem[] = ((data as unknown as RawCartRow[]) || []).map((row) => ({
      userId: row.user_id,
      variantId: row.variant_id,
      quantity: row.quantity,
      productName: row.variant?.product?.name || 'Sản phẩm',
      size: row.variant?.size || '',
      color: row.variant?.color || '',
      price: row.variant?.product?.price || 0,
      stock: row.variant?.stock || 0,
      thumbnailUrl: row.variant?.product?.thumbnail_url || null,
      updatedAt: row.updated_at,
    }));

    const totalItems = items.reduce((acc, i) => acc + i.quantity, 0);
    const subtotal = items.reduce((acc, i) => acc + i.price * i.quantity, 0);

    return { items, totalItems, subtotal };
  }

  async upsertItem(userId: string, variantId: string, quantity: number): Promise<void> {
    const { error } = await this.db.from('cart_items').upsert(
      {
        user_id: userId,
        variant_id: variantId,
        quantity,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id,variant_id' }
    );

    if (error) {
      throw new InfraError('DB_CART_UPSERT_FAILED', error);
    }
  }

  async removeItem(userId: string, variantId: string): Promise<void> {
    const { error } = await this.db
      .from('cart_items')
      .delete()
      .eq('user_id', userId)
      .eq('variant_id', variantId);

    if (error) {
      throw new InfraError('DB_CART_REMOVE_FAILED', error);
    }
  }
}
