import { SupabaseClient } from '@supabase/supabase-js';
import { Category } from '../../domain/entities/category.js';
import { CategoryRepository } from '../../domain/repositories/category.repository.js';
import { InfraError } from '../../domain/errors.js';

export class SupabaseCategoryRepository implements CategoryRepository {
  constructor(private readonly db: SupabaseClient) {}

  async listAll(): Promise<Category[]> {
    const { data, error } = await this.db
      .from('categories')
      .select('id, name, slug, sort_order')
      .order('sort_order', { ascending: true });

    if (error) {
      throw new InfraError('DB_CATEGORIES_QUERY_FAILED', error);
    }

    return (data || []).map((c) => ({
      id: c.id,
      name: c.name,
      slug: c.slug,
      sortOrder: c.sort_order,
    }));
  }

  async findById(id: string): Promise<Category | null> {
    const { data, error } = await this.db
      .from('categories')
      .select('id, name, slug, sort_order')
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new InfraError('DB_CATEGORY_QUERY_FAILED', error);
    }
    if (!data) return null;

    return {
      id: data.id,
      name: data.name,
      slug: data.slug,
      sortOrder: data.sort_order,
    };
  }
}
