import { z } from 'zod';

const phoneSchema = z
  .string()
  .trim()
  .min(9, 'Số điện thoại tối thiểu 9 số')
  .max(20, 'Số điện thoại tối đa 20 số')
  .regex(/^[0-9+\s.-]+$/, 'Số điện thoại không hợp lệ');

export const createAddressSchema = z.object({
  recipientName: z
    .string()
    .trim()
    .min(2, 'Họ và tên người nhận tối thiểu 2 ký tự')
    .max(100, 'Họ và tên người nhận tối đa 100 ký tự'),
  phone: phoneSchema,
  province: z.string().trim().min(1, 'Vui lòng chọn tỉnh/thành phố').max(100),
  district: z.string().trim().min(1, 'Vui lòng chọn quận/huyện').max(100),
  ward: z.string().trim().min(1, 'Vui lòng chọn phường/xã').max(100),
  detailAddress: z
    .string()
    .trim()
    .min(3, 'Địa chỉ chi tiết tối thiểu 3 ký tự')
    .max(255, 'Địa chỉ chi tiết tối đa 255 ký tự'),
  isDefault: z.boolean().optional(),
});

export const updateAddressSchema = z
  .object({
    recipientName: z.string().trim().min(2).max(100).optional(),
    phone: phoneSchema.optional(),
    province: z.string().trim().min(1).max(100).optional(),
    district: z.string().trim().min(1).max(100).optional(),
    ward: z.string().trim().min(1).max(100).optional(),
    detailAddress: z.string().trim().min(3).max(255).optional(),
    isDefault: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Không có thông tin nào để cập nhật',
  });

export const addressIdSchema = z.object({
  id: z.string().trim().min(1, 'Thiếu mã địa chỉ'),
});
