import { ProductSummary } from '../../../domain/entities/product.js';
import { Page } from '../../../domain/pagination.js';
import {
  ProductRepository,
  ProductSort,
} from '../../../domain/repositories/product.repository.js';
import { Cache } from '../../ports/cache.js';
import { decodeCursor, encodeCursor } from '../../cursor.js';
import { normalizeSearch } from '../../../shared/text.js';

export interface ListProductsInput {
  limit: number;
  cursor?: string;
  sort: ProductSort;
  categoryId?: string;
  q?: string;
  minPrice?: number;
  maxPrice?: number;
}

export class ListProducts {
  constructor(
    private readonly repo: ProductRepository,
    private readonly cache: Cache<Page<ProductSummary>>
  ) {}

  async execute(i: ListProductsInput): Promise<Page<ProductSummary>> {
    const cacheable =
      !i.cursor &&
      !i.q &&
      !i.categoryId &&
      i.minPrice == null &&
      i.maxPrice == null;
    const key = `p1:${i.sort}:${i.limit}`;

    if (cacheable) {
      const hit = this.cache.get(key);
      if (hit) return hit;
    }

    const rows = await this.repo.list({
      limit: i.limit + 1,
      sort: i.sort,
      cursor: i.cursor ? decodeCursor(i.cursor) : undefined,
      categoryId: i.categoryId,
      search: i.q ? normalizeSearch(i.q) : undefined,
      minPrice: i.minPrice,
      maxPrice: i.maxPrice,
    });

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
}
