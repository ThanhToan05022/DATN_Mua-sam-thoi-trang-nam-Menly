import { SupabaseClient } from '@supabase/supabase-js';
import { ProductSummary, ProductDetail, Cursor, AppError } from './types.js';
import { MOCK_PRODUCTS } from './mock-data.js';

export type ProductSort = 'newest' | 'price_asc' | 'price_desc';

export interface ProductQuery {
  limit: number;
  sort: ProductSort;
  cursor?: Cursor;
  categoryId?: string;
  search?: string;
  minPrice?: number;
  maxPrice?: number;
  includeInactive?: boolean;
}

export interface IProductModel {
  list(q: ProductQuery): Promise<ProductSummary[]>;
  findById(id: string): Promise<ProductDetail | null>;
  create(data: Omit<ProductDetail, 'id' | 'createdAt'>): Promise<ProductDetail>;
  update(id: string, data: Partial<ProductDetail>): Promise<ProductDetail>;
}

const SORTS = {
  newest: { col: 'created_at', asc: false },
  price_asc: { col: 'price', asc: true },
  price_desc: { col: 'price', asc: false },
} as const;

export class ProductModel implements IProductModel {
  private inMemoryProducts: ProductDetail[] = [...MOCK_PRODUCTS];

  constructor(private readonly supabase?: SupabaseClient) {}

  async list(q: ProductQuery): Promise<ProductSummary[]> {
    if (this.supabase) {
      const { col, asc } = SORTS[q.sort];
      let qb = this.supabase
        .from('products')
        .select(`
          id, category_id, name, slug, price, thumbnail_url, created_at,
          variants:product_variants(id, product_id, size, color, sku, stock)
        `);

      if (!q.includeInactive) qb = qb.eq('is_active', true);
      if (q.categoryId) qb = qb.eq('category_id', q.categoryId);
      if (q.search) qb = qb.ilike('search_text', `%${q.search.replace(/[\\%_]/g, '\\$&')}%`);
      if (q.minPrice != null) qb = qb.gte('price', q.minPrice);
      if (q.maxPrice != null) qb = qb.lte('price', q.maxPrice);

      if (q.cursor) {
        const op = asc ? 'gt' : 'lt';
        qb = qb.or(`${col}.${op}.${q.cursor.v},and(${col}.eq.${q.cursor.v},id.${op}.${q.cursor.id})`);
      }

      const { data, error } = await qb
        .order(col, { ascending: asc })
        .order('id', { ascending: asc })
        .limit(q.limit);

      if (error) throw new AppError('DB_PRODUCTS_FAILED', 500, error.message);
      return (data || []).map((row: any) => ({
        id: row.id,
        categoryId: row.category_id,
        name: row.name,
        slug: row.slug,
        price: row.price,
        thumbnailUrl: row.thumbnail_url,
        createdAt: row.created_at,
        variants: (row.variants || []).map((v: any) => ({
          id: v.id,
          productId: v.product_id,
          size: v.size,
          color: v.color,
          sku: v.sku,
          stock: v.stock,
        })),
      }));
    }

    let filtered = this.inMemoryProducts.filter((p) => q.includeInactive || p.isActive);
    if (q.categoryId) filtered = filtered.filter((p) => p.categoryId === q.categoryId);
    if (q.minPrice != null) filtered = filtered.filter((p) => p.price >= q.minPrice!);
    if (q.maxPrice != null) filtered = filtered.filter((p) => p.price <= q.maxPrice!);
    if (q.search) {
      filtered = filtered.filter((p) => p.name.toLowerCase().includes(q.search!.toLowerCase()));
    }

    if (q.sort === 'newest') {
      filtered.sort((a, b) => b.createdAt.localeCompare(a.createdAt) || b.id.localeCompare(a.id));
    } else if (q.sort === 'price_asc') {
      filtered.sort((a, b) => a.price - b.price || a.id.localeCompare(b.id));
    } else {
      filtered.sort((a, b) => b.price - a.price || b.id.localeCompare(a.id));
    }

    if (q.cursor) {
      const cursorVal = q.cursor.v;
      const idx = filtered.findIndex((p) => {
        if (q.sort === 'newest') {
          return p.createdAt < String(cursorVal) || (p.createdAt === String(cursorVal) && p.id < q.cursor!.id);
        } else if (q.sort === 'price_asc') {
          return p.price > Number(cursorVal) || (p.price === Number(cursorVal) && p.id > q.cursor!.id);
        } else {
          return p.price < Number(cursorVal) || (p.price === Number(cursorVal) && p.id < q.cursor!.id);
        }
      });
      if (idx !== -1) filtered = filtered.slice(idx);
    }

    return filtered.slice(0, q.limit).map((p) => ({
      id: p.id,
      name: p.name,
      slug: p.slug,
      price: p.price,
      categoryId: p.categoryId,
      thumbnailUrl: p.thumbnailUrl,
      createdAt: p.createdAt,
      variants: p.variants,
    }));
  }

  async findById(id: string): Promise<ProductDetail | null> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('products')
        .select(`
          id, category_id, name, slug, description, price, thumbnail_url, is_active, created_at,
          variants:product_variants(id, product_id, size, color, sku, stock),
          images:product_images(id, product_id, url, sort_order)
        `)
        .eq('id', id)
        .maybeSingle();

      if (error) throw new AppError('DB_PRODUCT_DETAIL_FAILED', 500, error.message);
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

    return this.inMemoryProducts.find((p) => p.id === id) || null;
  }

  async create(data: Omit<ProductDetail, 'id' | 'createdAt'>): Promise<ProductDetail> {
    const item: ProductDetail = {
      ...data,
      id: `p-${Date.now()}`,
      createdAt: new Date().toISOString(),
    };
    this.inMemoryProducts.push(item);
    return item;
  }

  async update(id: string, data: Partial<ProductDetail>): Promise<ProductDetail> {
    if (this.supabase) {
      try {
        const patch: Record<string, unknown> = {};
        if (data.name !== undefined) patch.name = data.name;
        if (data.slug !== undefined) patch.slug = data.slug;
        if (data.price !== undefined) patch.price = data.price;
        if (data.categoryId !== undefined) patch.category_id = data.categoryId;
        if (data.description !== undefined) patch.description = data.description;
        if (data.thumbnailUrl !== undefined) patch.thumbnail_url = data.thumbnailUrl;
        if (data.isActive !== undefined) patch.is_active = data.isActive;

        if (Object.keys(patch).length > 0) {
          await this.supabase.from('products').update(patch).eq('id', id);
        }
      } catch {
        // Fallback to in-memory
      }
    }

    const idx = this.inMemoryProducts.findIndex((p) => p.id === id);
    if (idx !== -1) {
      this.inMemoryProducts[idx] = { ...this.inMemoryProducts[idx], ...data };
      return this.inMemoryProducts[idx];
    }
    const current = await this.findById(id);
    if (!current) throw new AppError('NOT_FOUND', 404, 'Sản phẩm không tồn tại');
    return { ...current, ...data };
  }
}
