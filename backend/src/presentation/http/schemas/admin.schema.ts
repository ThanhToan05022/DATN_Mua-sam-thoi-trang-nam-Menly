import { z } from 'zod';

export const adjustStockSchema = z.object({
  variantId: z.string().min(1),
  delta: z.number().int(),
  reason: z.enum(['admin_restock', 'admin_correction']),
  note: z.string().max(255).optional(),
});

export const updateOrderStatusSchema = z.object({
  status: z.enum(['pending_payment', 'paid', 'processing', 'shipping', 'completed', 'cancelled']),
  note: z.string().max(255).optional(),
});

export const setUserRoleSchema = z.object({
  role: z.enum(['customer', 'admin']),
});

export const adminOrdersQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(200).default(20),
  status: z.enum(['pending_payment', 'paid', 'processing', 'shipping', 'completed', 'cancelled']).optional(),
  cursor: z.string().max(300).optional(),
  fromDate: z.string().max(50).optional(),
  toDate: z.string().max(50).optional(),
  day: z.string().max(50).optional(),
});
