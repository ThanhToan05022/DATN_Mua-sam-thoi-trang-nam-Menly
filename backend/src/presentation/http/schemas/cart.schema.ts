import { z } from 'zod';

export const upsertCartItemSchema = z.object({
  variantId: z.string().min(1),
  quantity: z.number().int().min(0).max(20),
});

export const removeCartItemParamSchema = z.object({
  variantId: z.string().min(1),
});
