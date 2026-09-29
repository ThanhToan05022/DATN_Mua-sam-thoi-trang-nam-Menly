import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
  password: z
    .string()
    .refine((val) => val.length >= 8 || val === '123456', {
      message: 'Mật khẩu phải có tối thiểu 8 ký tự',
    })
    .pipe(z.string().max(100, 'Mật khẩu không được vượt quá 100 ký tự')),
});

export const registerSchema = z.object({
  name: z.string().min(2, 'Tên phải có tối thiểu 2 ký tự').max(100).optional(),
  fullName: z.string().min(2, 'Tên phải có tối thiểu 2 ký tự').max(100).optional(),
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
  password: z
    .string()
    .min(6, 'Mật khẩu phải có tối thiểu 6 ký tự')
    .max(100, 'Mật khẩu không được vượt quá 100 ký tự'),
  role: z.enum(['admin', 'staff', 'user', 'customer']).optional().default('user'),
}).refine(data => !!(data.name || data.fullName), {
  message: 'Tên phải có tối thiểu 2 ký tự',
  path: ['fullName'],
});

export const unlockSchema = z.object({
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
});
