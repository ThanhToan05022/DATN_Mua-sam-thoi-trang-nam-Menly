import { SupabaseClient } from '@supabase/supabase-js';
import { ProductSummary, ProductDetail, Cursor, AppError } from './types.js';
import { MOCK_PRODUCTS } from './mock-data.js';
import { env } from '../config/env.js';
import { createSupabaseClient } from '../infrastructure/supabase/client.js';

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

export interface CreateProductInput {
  categoryId: string;
  name: string;
  description: string | null;
  price: number;
  thumbnailUrl: string | null;
  isActive: boolean;
  variants: Array<Pick<ProductDetail['variants'][number], 'size' | 'color' | 'sku' | 'stock'>>;
  images: string[];
}

export interface IProductModel {
  list(q: ProductQuery, accessToken?: string): Promise<ProductSummary[]>;
  findById(id: string, accessToken?: string): Promise<ProductDetail | null>;
  create(data: CreateProductInput, accessToken?: string): Promise<ProductDetail>;
  update(id: string, data: Partial<ProductDetail>, accessToken?: string): Promise<ProductDetail>;
}

const SORTS = {
  newest: { col: 'created_at', asc: false },
  price_asc: { col: 'price', asc: true },
  price_desc: { col: 'price', asc: false },
} as const;

const toSlug = (value: string): string => value
  .toLowerCase()
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .replace(/[đĐ]/g, 'd')
  .replace(/[^a-z0-9]+/g, '-')
  .replace(/(^-|-$)/g, '');

const normalizeSearchText = (value: string): string => value
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .replace(/[đĐ]/g, 'd')
  .toLowerCase()
  .trim();

export class ProductModel implements IProductModel {
  private inMemoryProducts: ProductDetail[] = [...MOCK_PRODUCTS];

  constructor(private readonly supabase?: SupabaseClient) {}

  private getRequestClient(accessToken?: string): SupabaseClient | undefined {
    if (!this.supabase || !accessToken || env.SUPABASE_SERVICE_ROLE_KEY) {
      return this.supabase;
    }

    // Dùng JWT của phiên admin để Supabase áp dụng quyền RLS tương ứng.
    return createSupabaseClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, accessToken);
  }

  async list(q: ProductQuery, accessToken?: string): Promise<ProductSummary[]> {
    const supabase = this.getRequestClient(accessToken);
    if (supabase) {
      const { col, asc } = SORTS[q.sort];
      let qb = supabase
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

  async findById(id: string, accessToken?: string): Promise<ProductDetail | null> {
    const supabase = this.getRequestClient(accessToken);
    if (supabase) {
      const { data, error } = await supabase
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

  async create(data: CreateProductInput, accessToken?: string): Promise<ProductDetail> {
    const supabase = this.getRequestClient(accessToken);
    if (supabase) {
      const slug = toSlug(data.name);
      const { data: prod, error } = await supabase
        .from('products')
        .insert({
          category_id: data.categoryId,
          name: data.name,
          slug,
          description: data.description || '',
          price: data.price,
          thumbnail_url: data.thumbnailUrl,
          search_text: normalizeSearchText(`${slug} ${data.name} ${data.description || ''}`),
          is_active: data.isActive ?? true,
        })
        .select()
        .single();

      if (error || !prod) {
        throw new AppError('DB_PRODUCT_CREATE_FAILED', 400, error?.message || 'Không thể tạo sản phẩm');
      }

      const rollbackProduct = async () => {
        await supabase.from('products').delete().eq('id', prod.id);
      };

      const varRows = data.variants.map((v) => ({
          product_id: prod.id,
          size: v.size,
          color: v.color,
          sku: v.sku || toSlug(`${slug}-${v.size}-${v.color}`),
          stock: v.stock,
        }));
      const { data: createdVars, error: variantsError } = await supabase
        .from('product_variants')
        .insert(varRows)
        .select();
      if (variantsError) {
        await rollbackProduct();
        throw new AppError('DB_PRODUCT_VARIANTS_CREATE_FAILED', 400, variantsError.message);
      }

      const imageUrls = [...new Set(data.images.filter(Boolean))];
      let createdImages: any[] = [];
      if (imageUrls.length > 0) {
        const { data: images, error: imagesError } = await supabase
          .from('product_images')
          .insert(imageUrls.map((url, sortOrder) => ({ product_id: prod.id, url, sort_order: sortOrder })))
          .select();
        if (imagesError) {
          await rollbackProduct();
          throw new AppError('DB_PRODUCT_IMAGES_CREATE_FAILED', 400, imagesError.message);
        }
        createdImages = images || [];
      }

      return {
        id: prod.id,
        categoryId: prod.category_id,
        name: prod.name,
        slug: prod.slug,
        description: prod.description,
        price: prod.price,
        thumbnailUrl: prod.thumbnail_url,
        isActive: prod.is_active,
        createdAt: prod.created_at,
        variants: (createdVars || []).map((v: any) => ({
          id: v.id,
          productId: v.product_id,
          size: v.size,
          color: v.color,
          sku: v.sku,
          stock: v.stock,
        })),
        images: createdImages.map((image: any) => ({
          id: image.id,
          productId: image.product_id,
          url: image.url,
          sortOrder: image.sort_order,
        })),
      };
    }

    const id = `p-${Date.now()}`;
    const item: ProductDetail = {
      categoryId: data.categoryId,
      name: data.name,
      slug: toSlug(data.name),
      description: data.description,
      price: data.price,
      thumbnailUrl: data.thumbnailUrl,
      isActive: data.isActive,
      variants: data.variants.map((variant, index) => ({
        ...variant,
        id: `${id}-v${index + 1}`,
        productId: id,
        sku: variant.sku || toSlug(`${id}-${variant.size}-${variant.color}`),
      })),
      images: data.images.map((url, index) => ({ id: `${id}-i${index + 1}`, productId: id, url, sortOrder: index })),
      id,
      createdAt: new Date().toISOString(),
    };
    this.inMemoryProducts.push(item);
    return item;
  }

  async update(id: string, data: Partial<ProductDetail>, accessToken?: string): Promise<ProductDetail> {
    const supabase = this.getRequestClient(accessToken);
    if (supabase) {
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
          const { error } = await supabase.from('products').update(patch).eq('id', id);
          if (error) throw new AppError('DB_PRODUCT_UPDATE_FAILED', 400, error.message);
        }

        const updated = await this.findById(id, accessToken);
        if (updated) return updated;
      } catch (err) {
        if (err instanceof AppError) throw err;
      }
    }

    const idx = this.inMemoryProducts.findIndex((p) => p.id === id);
    if (idx !== -1) {
      this.inMemoryProducts[idx] = { ...this.inMemoryProducts[idx], ...data };
      return this.inMemoryProducts[idx];
    }
    const current = await this.findById(id, accessToken);
    if (!current) throw new AppError('NOT_FOUND', 404, 'Sản phẩm không tồn tại');
    return { ...current, ...data };
  }
}
