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

export const createProductSchema = z.object({
  categoryId: z.string().uuid(),
  name: z.string().trim().min(2).max(150),
  description: z.string().trim().max(5000).nullable().optional().transform((value) => value ?? null),
  price: z.coerce.number().int().min(0),
  thumbnailUrl: z.string().url().nullable().optional().transform((value) => value ?? null),
  images: z.array(z.string().url()).max(20).optional().default([]),
  isActive: z.boolean().optional().default(true),
  variants: z.array(z.object({
    size: z.string().trim().min(1).max(30),
    color: z.string().trim().min(1).max(60),
    sku: z.string().trim().max(100).optional().default(''),
    stock: z.coerce.number().int().min(0).default(0),
  })).min(1).max(100),
});
