import { z } from 'zod';

export const createOrderSchema = z.object({
  ship: z.object({
    name: z.string().trim().min(2).max(100),
    phone: z.string().trim().min(9).max(15),
    address: z.string().trim().min(5).max(255),
  }),
  paymentMethod: z.enum(['cod', 'vnpay']),
  items: z
    .array(
      z.object({
        variantId: z.string().min(1),
        quantity: z.number().int().min(1).max(20),
      })
    )
    .optional(),
});

export const trackOrderSchema = z.object({
  code: z.string().trim().min(4).max(50),
  phone: z.string().trim().min(8).max(15),
});

export const listOrdersQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20),
  cursor: z.string().max(300).optional(),
});
