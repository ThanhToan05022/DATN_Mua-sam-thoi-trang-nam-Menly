import { z } from 'zod';

const shipSchema = z.object({
  name: z.string().trim().min(2, 'Họ và tên người nhận tối thiểu 2 ký tự').max(100),
  phone: z.string().trim().min(9, 'Số điện thoại tối thiểu 9 số').max(20),
  address: z.string().trim().min(5, 'Địa chỉ giao hàng tối thiểu 5 ký tự').max(255),
});

/**
 * Chấp nhận cả `null` lẫn `undefined` khi validate, nhưng chuẩn hoá thành
 * `undefined` ở output để không phá kiểu của viewmodel (`T | undefined`).
 */
const nullish = <T extends z.ZodTypeAny>(schema: T) =>
  schema.nullish().transform((value) => value ?? undefined);

export const createOrderSchema = z
  .object({
    // Ưu tiên chọn địa chỉ đã lưu; nếu không thì nhập tay qua `ship`
    // Dùng `nullish()` thay vì `optional()`: client gửi key với giá trị null
    // (ví dụ voucherCode: null khi chưa chọn voucher) vẫn phải hợp lệ.
    addressId: nullish(z.string().trim().min(1).max(64)),
    ship: nullish(shipSchema),
    paymentMethod: z.enum(['cod', 'vnpay']),
    items: nullish(
      z.array(
        z.object({
          variantId: z.string().min(1),
          quantity: z.number().int().min(1).max(100),
        })
      )
    ),
    note: nullish(z.string().max(500)),
    voucherCode: nullish(z.string().trim().min(1).max(50)),
    discountAmount: nullish(z.number().int().min(0)),
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
