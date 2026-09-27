import { Category } from '../entities/category.js';

export interface CategoryRepository {
  listAll(): Promise<Category[]>;
  findById(id: string): Promise<Category | null>;
}
