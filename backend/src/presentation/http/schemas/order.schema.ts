import { z } from 'zod';

const shipSchema = z.object({
  name: z.string().trim().min(2, 'Họ và tên người nhận tối thiểu 2 ký tự').max(100),
  phone: z.string().trim().min(9, 'Số điện thoại tối thiểu 9 số').max(20),
  address: z.string().trim().min(5, 'Địa chỉ giao hàng tối thiểu 5 ký tự').max(255),
});

export const createOrderSchema = z
  .object({
    // Ưu tiên chọn địa chỉ đã lưu; nếu không thì nhập tay qua `ship`
    addressId: z.string().trim().min(1).max(64).optional(),
    ship: shipSchema.optional(),
    paymentMethod: z.enum(['cod', 'vnpay']),
    items: z
      .array(
        z.object({
          variantId: z.string().min(1),
          quantity: z.number().int().min(1).max(100),
        })
      )
      .optional(),
    note: z.string().max(500).optional(),
    voucherCode: z.string().max(50).optional(),
    discountAmount: z.number().int().min(0).optional(),
  })
  .refine((data) => Boolean(data.addressId) || Boolean(data.ship), {
    message: 'Vui lòng chọn địa chỉ giao hàng hoặc nhập thông tin nhận hàng',
    path: ['addressId'],
  });

export const trackOrderSchema = z.object({
  code: z.string().trim().min(4).max(50),
  phone: z.string().trim().min(8).max(15),
});

export const listOrdersQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20),
  cursor: z.string().max(300).optional(),
});
