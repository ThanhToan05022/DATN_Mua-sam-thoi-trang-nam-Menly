import { describe, it, expect } from 'vitest';
import { ProductViewModel } from '../../src/viewmodels/product.viewmodel.js';
import { ProductModel } from '../../src/models/product.model.js';
import { LruCache } from '../../src/infrastructure/cache/lru.js';

describe('ProductViewModel (MVVM Unit Test)', () => {
  it('should list products and return pageInfo', async () => {
    const model = new ProductModel();
    const cache = new LruCache<any>(10, 5000);
    const viewModel = new ProductViewModel(model, cache);

    const result = await viewModel.listProducts({
      limit: 2,
      sort: 'newest',
    });

    expect(result.items.length).toBe(2);
    expect(result.pageInfo.limit).toBe(2);
    expect(result.pageInfo.hasNext).toBe(true);
    expect(result.pageInfo.nextCursor).toBeDefined();
  });

  it('should hit cache for identical query on first page', async () => {
    const model = new ProductModel();
    const cache = new LruCache<any>(10, 5000);
    const viewModel = new ProductViewModel(model, cache);

    const r1 = await viewModel.listProducts({ limit: 10, sort: 'newest' });
    const r2 = await viewModel.listProducts({ limit: 10, sort: 'newest' });

    expect(r1).toBe(r2);
  });
});
