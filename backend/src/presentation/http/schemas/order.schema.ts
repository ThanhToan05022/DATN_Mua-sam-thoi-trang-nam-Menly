import { z } from 'zod';

export const createOrderSchema = z.object({
  ship: z.object({
    name: z.string().trim().min(2, 'Họ và tên người nhận tối thiểu 2 ký tự').max(100),
    phone: z.string().trim().min(9, 'Số điện thoại tối thiểu 9 số').max(20),
    address: z.string().trim().min(5, 'Địa chỉ giao hàng tối thiểu 5 ký tự').max(255),
  }),
  paymentMethod: z.enum(['cod', 'vnpay']),
  items: z
    .array(
      z.object({
        variantId: z.string().min(1),
        quantity: z.number().int().min(1).max(100),
      })
    )
    .optional(),
  note: z.string().optional(),
  voucherCode: z.string().optional(),
  discountAmount: z.number().int().min(0).optional(),
});

export const trackOrderSchema = z.object({
  code: z.string().trim().min(4).max(50),
  phone: z.string().trim().min(8).max(15),
});

export const listOrdersQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20),
  cursor: z.string().max(300).optional(),
});
