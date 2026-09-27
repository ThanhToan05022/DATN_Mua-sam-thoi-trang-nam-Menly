import { z } from 'zod';

export const createPaymentSchema = z.object({
  orderId: z.string().min(1),
});
