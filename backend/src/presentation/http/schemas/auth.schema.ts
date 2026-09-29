import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
  password: z
    .string()
    .min(6, 'Mật khẩu phải có tối thiểu 6 ký tự')
    .pipe(z.string().max(100, 'Mật khẩu không được vượt quá 100 ký tự')),
});

export const registerSchema = z.object({
  name: z.string().min(2, 'Tên phải có tối thiểu 2 ký tự').max(100),
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
  password: z
    .string()
    .min(6, 'Mật khẩu phải có tối thiểu 6 ký tự')
    .max(100, 'Mật khẩu không được vượt quá 100 ký tự'),
  role: z.enum(['admin', 'user']).optional().default('user'),
});

export const unlockSchema = z.object({
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
});
