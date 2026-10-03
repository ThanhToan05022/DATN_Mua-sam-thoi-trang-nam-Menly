import { SupabaseClient } from '@supabase/supabase-js';
import { ProductSummary, AppError } from './types.js';
import { IProductModel } from './product.model.js';

export interface IWishlistModel {
  getWishlist(userId: string): Promise<ProductSummary[]>;
  addToWishlist(userId: string, productId: string): Promise<void>;
  removeFromWishlist(userId: string, productId: string): Promise<void>;
  isFavorite(userId: string, productId: string): Promise<boolean>;
}

export class WishlistModel implements IWishlistModel {
  // InMemory fallback: Map<userId, Set<productId>>
  private inMemoryWishlists = new Map<string, Set<string>>();

  constructor(
    private readonly supabase?: SupabaseClient,
    private readonly productModel?: IProductModel
  ) {}

  async getWishlist(userId: string): Promise<ProductSummary[]> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('wishlists')
        .select(`
          product_id,
          created_at,
          product:products (
            id, category_id, name, slug, price, thumbnail_url, created_at,
            variants:product_variants(id, product_id, size, color, sku, stock)
          )
        `)
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) {
        throw new AppError('DB_QUERY_FAILED', 400, error.message);
      }

      return (data || [])
        .map((row: any) => {
          const p = row.product;
          if (!p) return null;
          return {
            id: p.id,
            categoryId: p.category_id,
            name: p.name,
            slug: p.slug,
            price: Number(p.price),
            thumbnailUrl: p.thumbnail_url,
            createdAt: p.created_at,
            variants: p.variants || [],
          } as ProductSummary;
        })
        .filter((item): item is ProductSummary => item !== null);
    }

    // InMemory
    const productIds = Array.from(this.inMemoryWishlists.get(userId) || []);
    if (!this.productModel || productIds.length === 0) return [];

    const products: ProductSummary[] = [];
    for (const pid of productIds) {
      const p = await this.productModel.findById(pid);
      if (p) {
        products.push({
          id: p.id,
          categoryId: p.categoryId,
          name: p.name,
          slug: p.slug,
          price: p.price,
          thumbnailUrl: p.thumbnailUrl,
          createdAt: p.createdAt,
          variants: p.variants,
        });
      }
    }
    return products;
  }

  async addToWishlist(userId: string, productId: string): Promise<void> {
    if (this.supabase) {
      const { error } = await this.supabase
        .from('wishlists')
        .upsert(
          { user_id: userId, product_id: productId },
          { onConflict: 'user_id,product_id' }
        );

      if (error) {
        throw new AppError('DB_INSERT_FAILED', 400, error.message);
      }
      return;
    }

    // InMemory
    if (!this.inMemoryWishlists.has(userId)) {
      this.inMemoryWishlists.set(userId, new Set());
    }
    this.inMemoryWishlists.get(userId)!.add(productId);
  }

  async removeFromWishlist(userId: string, productId: string): Promise<void> {
    if (this.supabase) {
      const { error } = await this.supabase
        .from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);

      if (error) {
        throw new AppError('DB_DELETE_FAILED', 400, error.message);
      }
      return;
    }

    // InMemory
    if (this.inMemoryWishlists.has(userId)) {
      this.inMemoryWishlists.get(userId)!.delete(productId);
    }
  }

  async isFavorite(userId: string, productId: string): Promise<boolean> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('wishlists')
        .select('product_id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

      if (error) return false;
      return !!data;
    }

    // InMemory
    const set = this.inMemoryWishlists.get(userId);
    return set ? set.has(productId) : false;
  }
}
