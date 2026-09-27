import { SupabaseClient } from '@supabase/supabase-js';
import {
  ProductSummary,
  ProductDetail,
} from '../../domain/entities/product.js';
import {
  ProductRepository,
  ProductQuery,
} from '../../domain/repositories/product.repository.js';
import { InfraError } from '../../domain/errors.js';

const SORTS = {
  newest: { col: 'created_at', asc: false },
  price_asc: { col: 'price', asc: true },
  price_desc: { col: 'price', asc: false },
} as const;

export class SupabaseProductRepository implements ProductRepository {
  constructor(private readonly db: SupabaseClient) {}

  async list(q: ProductQuery): Promise<ProductSummary[]> {
    const { col, asc } = SORTS[q.sort];
    let qb = this.db
      .from('products')
      .select('id, name, slug, price, thumbnail_url, created_at');

    if (!q.includeInactive) {
      qb = qb.eq('is_active', true);
    }
    if (q.categoryId) {
      qb = qb.eq('category_id', q.categoryId);
    }
    if (q.search) {
      qb = qb.ilike('search_text', `%${q.search.replace(/[\\%_]/g, '\\$&')}%`);
    }
    if (q.minPrice != null) {
      qb = qb.gte('price', q.minPrice);
    }
    if (q.maxPrice != null) {
      qb = qb.lte('price', q.maxPrice);
    }

    if (q.cursor) {
      const op = asc ? 'gt' : 'lt';
      qb = qb.or(
        `${col}.${op}.${q.cursor.v},and(${col}.eq.${q.cursor.v},id.${op}.${q.cursor.id})`
      );
    }

    const { data, error } = await qb
      .order(col, { ascending: asc })
      .order('id', { ascending: asc })
      .limit(q.limit);

    if (error) {
      throw new InfraError('DB_PRODUCTS_QUERY_FAILED', error);
    }

    return (data || []).map((row) => ({
      id: row.id,
      name: row.name,
      slug: row.slug,
      price: row.price,
      thumbnailUrl: row.thumbnail_url,
      createdAt: row.created_at,
    }));
  }

  async findById(id: string): Promise<ProductDetail | null> {
    const { data, error } = await this.db
      .from('products')
      .select(`
        id, category_id, name, slug, description, price, thumbnail_url, is_active, created_at,
        variants:product_variants(id, product_id, size, color, sku, stock),
        images:product_images(id, product_id, url, sort_order)
      `)
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new InfraError('DB_PRODUCT_DETAIL_QUERY_FAILED', error);
    }
    if (!data) return null;

    type RawVariant = { id: string; product_id: string; size: string; color: string; sku: string; stock: number };
    type RawImage = { id: string; product_id: string; url: string; sort_order: number };

    return {
      id: data.id,
      categoryId: data.category_id,
      name: data.name,
      slug: data.slug,
      description: data.description,
      price: data.price,
      thumbnailUrl: data.thumbnail_url,
      isActive: data.is_active,
      createdAt: data.created_at,
      variants: ((data.variants as unknown as RawVariant[]) || []).map((v) => ({
        id: v.id,
        productId: v.product_id,
        size: v.size,
        color: v.color,
        sku: v.sku,
        stock: v.stock,
      })),
      images: ((data.images as unknown as RawImage[]) || []).map((img) => ({
        id: img.id,
        productId: img.product_id,
        url: img.url,
        sortOrder: img.sort_order,
      })),
    };
  }

  async create(data: Omit<ProductDetail, 'id' | 'createdAt'>): Promise<ProductDetail> {
    const { data: created, error } = await this.db
      .from('products')
      .insert({
        category_id: data.categoryId,
        name: data.name,
        slug: data.slug,
        description: data.description,
        price: data.price,
        thumbnail_url: data.thumbnailUrl,
        is_active: data.isActive,
      })
      .select()
      .single();

    if (error || !created) {
      throw new InfraError('DB_PRODUCT_CREATE_FAILED', error);
    }

    return this.findById(created.id) as Promise<ProductDetail>;
  }

  async update(id: string, data: Partial<ProductDetail>): Promise<ProductDetail> {
    const updates: Record<string, unknown> = {};
    if (data.name !== undefined) updates.name = data.name;
    if (data.description !== undefined) updates.description = data.description;
    if (data.price !== undefined) updates.price = data.price;
    if (data.thumbnailUrl !== undefined) updates.thumbnail_url = data.thumbnailUrl;
    if (data.isActive !== undefined) updates.is_active = data.isActive;

    const { error } = await this.db.from('products').update(updates).eq('id', id);
    if (error) {
      throw new InfraError('DB_PRODUCT_UPDATE_FAILED', error);
    }

    return this.findById(id) as Promise<ProductDetail>;
  }
}
