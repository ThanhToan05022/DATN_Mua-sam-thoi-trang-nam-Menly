import { Category } from '../../../domain/entities/category.js';
import { CategoryRepository } from '../../../domain/repositories/category.repository.js';
import { Cache } from '../../ports/cache.js';

export class ListCategories {
  constructor(
    private readonly repo: CategoryRepository,
    private readonly cache: Cache<Category[]>
  ) {}

  async execute(): Promise<Category[]> {
    const key = 'categories:all';
    const cached = this.cache.get(key);
    if (cached) return cached;

    const categories = await this.repo.listAll();
    this.cache.set(key, categories);
    return categories;
  }
}
