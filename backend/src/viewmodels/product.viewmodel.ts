import { ProductSummary, ProductDetail, Page, AppError } from '../models/types.js';
import { CreateProductInput, IProductModel, ProductSort } from '../models/product.model.js';
import { Cache } from '../application/ports/cache.js';
import { decodeCursor, encodeCursor, normalizeSearch } from './base.viewmodel.js';

export interface ProductListInput {
  limit: number;
  cursor?: string;
  sort: ProductSort;
  categoryId?: string;
  q?: string;
  minPrice?: number;
  maxPrice?: number;
  includeInactive?: boolean;
  accessToken?: string;
}

export class ProductViewModel {
  constructor(
    private readonly model: IProductModel,
    private readonly cache: Cache<Page<ProductSummary>>
  ) {}

  async listProducts(i: ProductListInput): Promise<Page<ProductSummary>> {
    const cacheable =
      !i.cursor &&
      !i.q &&
      !i.categoryId &&
      i.minPrice == null &&
      i.maxPrice == null &&
      !i.includeInactive;
    const key = `p1:${i.sort}:${i.limit}`;

    if (cacheable) {
      const hit = this.cache.get(key);
      if (hit) return hit;
    }

    const rows = await this.model.list({
      limit: i.limit + 1,
      sort: i.sort,
      cursor: i.cursor ? decodeCursor(i.cursor) : undefined,
      categoryId: i.categoryId,
      search: i.q ? normalizeSearch(i.q) : undefined,
      minPrice: i.minPrice,
      maxPrice: i.maxPrice,
      includeInactive: i.includeInactive,
    }, i.accessToken);

    const hasNext = rows.length > i.limit;
    const items = hasNext ? rows.slice(0, i.limit) : rows;
    const last = items.at(-1);

    const page: Page<ProductSummary> = {
      items,
      pageInfo: {
        limit: i.limit,
        hasNext,
        nextCursor:
          hasNext && last
            ? encodeCursor({
                v: i.sort === 'newest' ? last.createdAt : last.price,
                id: last.id,
              })
            : null,
      },
    };

    if (cacheable) {
      this.cache.set(key, page);
    }

    return page;
  }

  async getProductDetail(id: string): Promise<ProductDetail> {
    const product = await this.model.findById(id);
    if (!product || !product.isActive) {
      throw new AppError('NOT_FOUND', 404, 'Sản phẩm không tồn tại');
    }
    return product;
  }

  async getAdminProductDetail(id: string, accessToken?: string): Promise<ProductDetail> {
    const product = await this.model.findById(id, accessToken);
    if (!product) {
      throw new AppError('NOT_FOUND', 404, 'Sản phẩm không tồn tại');
    }
    return product;
  }

  async updateProduct(id: string, data: Partial<ProductDetail>, accessToken?: string): Promise<ProductDetail> {
    const updated = await this.model.update(id, data, accessToken);
    this.cache.clear();
    return updated;
  }

  async deleteProduct(id: string, accessToken?: string): Promise<void> {
    await this.model.update(id, { isActive: false }, accessToken);
    this.cache.clear();
  }

  async createProduct(data: CreateProductInput, accessToken?: string): Promise<ProductDetail> {
    const created = await this.model.create(data, accessToken);
    this.cache.clear();
    return created;
  }
}
