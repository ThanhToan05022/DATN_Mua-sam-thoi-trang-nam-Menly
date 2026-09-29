import { z } from 'zod';

export const listProductsSchema = z.object({
  limit: z.coerce.number().int().min(1).max(500).default(20),
  cursor: z.string().max(300).optional(),
  sort: z.enum(['newest', 'price_asc', 'price_desc']).default('newest'),
  categoryId: z.string().optional(),
  q: z.string().trim().min(1).max(60).optional(),
  minPrice: z.coerce.number().int().min(0).optional(),
  maxPrice: z.coerce.number().int().min(0).optional(),
});

export const productIdParamSchema = z.object({
  id: z.string().min(1),
});
