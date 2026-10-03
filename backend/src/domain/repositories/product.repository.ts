import { ProductSummary, ProductDetail } from '../entities/product.js';
import { Cursor } from '../pagination.js';

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

export interface ProductRepository {
  list(q: ProductQuery): Promise<ProductSummary[]>;
  findById(id: string): Promise<ProductDetail | null>;
  create(data: Omit<ProductDetail, 'id' | 'createdAt'>): Promise<ProductDetail>;
  update(id: string, data: Partial<ProductDetail>): Promise<ProductDetail>;
}
