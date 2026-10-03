import { SupabaseClient } from '@supabase/supabase-js';
import { Cart, CartItem, AppError } from './types.js';
import { MOCK_PRODUCTS } from './mock-data.js';

export interface ICartModel {
  getByUserId(userId: string): Promise<Cart>;
  upsertItem(userId: string, variantId: string, quantity: number): Promise<void>;
  removeItem(userId: string, variantId: string): Promise<void>;
  clear(userId: string): Promise<void>;
}

export class CartModel implements ICartModel {
  private inMemoryCarts = new Map<string, Map<string, number>>();

  constructor(private readonly supabase?: SupabaseClient) {}

  async getByUserId(userId: string): Promise<Cart> {
    if (this.supabase) {
      const { data, error } = await this.supabase
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

      if (error) throw new AppError('DB_CART_FAILED', 500, error.message);

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

    const userCart = this.inMemoryCarts.get(userId) || new Map<string, number>();
    const items: CartItem[] = [];

    for (const [variantId, qty] of userCart.entries()) {
      let foundVariant: any;
      let foundProduct: any;

      for (const p of MOCK_PRODUCTS) {
        const v = p.variants?.find((vt: any) => vt.id === variantId);
        if (v) {
          foundVariant = v;
          foundProduct = p;
          break;
        }
      }

      if (foundProduct && foundVariant) {
        items.push({
          userId,
          variantId,
          quantity: qty,
          productName: foundProduct.name,
          size: foundVariant.size,
          color: foundVariant.color,
          price: foundProduct.price,
          stock: foundVariant.stock ?? 50,
          thumbnailUrl: foundProduct.thumbnailUrl || null,
          updatedAt: new Date().toISOString(),
        });
      } else {
        items.push({
          userId,
          variantId,
          quantity: qty,
          productName: 'Sản phẩm Menly',
          size: 'M',
          color: 'Trắng',
          price: 350000,
          stock: 25,
          thumbnailUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600',
          updatedAt: new Date().toISOString(),
        });
      }
    }

    const totalItems = items.reduce((acc, i) => acc + i.quantity, 0);
    const subtotal = items.reduce((acc, i) => acc + i.price * i.quantity, 0);
    return { items, totalItems, subtotal };
  }

  async upsertItem(userId: string, variantId: string, quantity: number): Promise<void> {
    if (this.supabase) {
      const { error } = await this.supabase.from('cart_items').upsert(
        {
          user_id: userId,
          variant_id: variantId,
          quantity,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,variant_id' }
      );
      if (error) throw new AppError('DB_CART_UPSERT_FAILED', 500, error.message);
      return;
    }

    if (!this.inMemoryCarts.has(userId)) this.inMemoryCarts.set(userId, new Map());
    this.inMemoryCarts.get(userId)!.set(variantId, quantity);
  }

  async removeItem(userId: string, variantId: string): Promise<void> {
    if (this.supabase) {
      const { error } = await this.supabase
        .from('cart_items')
        .delete()
        .eq('user_id', userId)
        .eq('variant_id', variantId);
      if (error) throw new AppError('DB_CART_REMOVE_FAILED', 500, error.message);
      return;
    }

    this.inMemoryCarts.get(userId)?.delete(variantId);
  }

  async clear(userId: string): Promise<void> {
    if (this.supabase) {
      const { error } = await this.supabase
        .from('cart_items')
        .delete()
        .eq('user_id', userId);
      if (error) throw new AppError('DB_CART_CLEAR_FAILED', 500, error.message);
      return;
    }

    this.inMemoryCarts.delete(userId);
  }
}
