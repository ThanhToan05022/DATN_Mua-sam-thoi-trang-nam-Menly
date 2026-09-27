import { Category } from '../models/types.js';
import { ICategoryModel } from '../models/category.model.js';
import { Cache } from '../application/ports/cache.js';

export class CategoryViewModel {
  constructor(
    private readonly model: ICategoryModel,
    private readonly cache: Cache<Category[]>
  ) {}

  async getCategories(): Promise<Category[]> {
    const key = 'categories:all';
    const hit = this.cache.get(key);
    if (hit) return hit;

    const data = await this.model.listAll();
    this.cache.set(key, data);
    return data;
  }
}
