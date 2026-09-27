import { SupabaseClient } from '@supabase/supabase-js';
import { Category, AppError } from './types.js';
import { MOCK_CATEGORIES } from './mock-data.js';

export interface ICategoryModel {
  listAll(): Promise<Category[]>;
  findById(id: string): Promise<Category | null>;
}

export class CategoryModel implements ICategoryModel {
  private inMemoryCategories: Category[] = [...MOCK_CATEGORIES];

  constructor(private readonly supabase?: SupabaseClient) {}

  async listAll(): Promise<Category[]> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('categories')
        .select('id, name, slug, sort_order')
        .order('sort_order', { ascending: true });

      if (error) throw new AppError('DB_CATEGORIES_FAILED', 500, error.message);
      return (data || []).map((c) => ({
        id: c.id,
        name: c.name,
        slug: c.slug,
        sortOrder: c.sort_order,
      }));
    }

    return [...this.inMemoryCategories].sort((a, b) => a.sortOrder - b.sortOrder);
  }

  async findById(id: string): Promise<Category | null> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('categories')
        .select('id, name, slug, sort_order')
        .eq('id', id)
        .maybeSingle();

      if (error) throw new AppError('DB_CATEGORY_FAILED', 500, error.message);
      if (!data) return null;
      return {
        id: data.id,
        name: data.name,
        slug: data.slug,
        sortOrder: data.sort_order,
      };
    }

    return this.inMemoryCategories.find((c) => c.id === id) || null;
  }
}
