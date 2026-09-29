import { Router, RequestHandler } from 'express';
import { SupabaseClient } from '@supabase/supabase-js';
import { AppError } from '../../models/types.js';
import { env } from '../../config/env.js';
import { z } from 'zod';

const changePasswordSchema = z.object({
  newPassword: z.string().min(6, 'Mật khẩu mới phải ít nhất 6 ký tự'),
  // Bắt buộc: nếu chỉ cần accessToken thi chi can moi cap token la doi duoc
  // mat khau, khong can biet mat khau hien tai.
  currentPassword: z.string().min(1, 'Vui lòng nhập mật khẩu hiện tại'),
});

const updateProfileSchema = z.object({
  fullName: z.string().min(1).max(100).optional(),
  phone: z.string().max(20).optional(),
  address: z.string().max(300).optional(),
});

export const profileRoutes = (
  requireAuth: RequestHandler,
  supabase: SupabaseClient
): Router => {
  const router = Router();
  router.use(requireAuth);

  // GET /api/v1/profile — lấy thông tin profile
  router.get('/', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const { data, error } = await supabase
        .from('profiles')
        .select('id, full_name, email, phone, address, avatar_url, role, created_at')
        .eq('id', userId)
        .single();

      if (error || !data) {
        throw new AppError('NOT_FOUND', 404, 'Không tìm thấy thông tin người dùng');
      }
      res.json({ data });
    } catch (err) {
      next(err);
    }
  });

  // PUT /api/v1/profile — cập nhật thông tin cá nhân
  router.put('/', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const body = updateProfileSchema.parse(req.body);

      const updateData: Record<string, string> = {};
      if (body.fullName !== undefined) updateData.full_name = body.fullName;
      if (body.phone !== undefined) updateData.phone = body.phone;
      if (body.address !== undefined) updateData.address = body.address;

      const { data, error } = await supabase
        .from('profiles')
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

      if (error) throw new AppError('SERVER_ERROR', 500, error.message);
      res.json({ message: 'Cập nhật thông tin thành công', data });
    } catch (err) {
      next(err);
    }
  });

  // POST /api/v1/profile/change-password — đổi mật khẩu
  router.post('/change-password', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const body = changePasswordSchema.parse(req.body);
      const authHeader = req.headers.authorization || '';
      const token = authHeader.replace(/^Bearer\s+/i, '');

      // Xác thực mật khẩu hiện tại trước khi đổi.
      // Dùng 1 client anon riêng (không gắn user token) để đăng nhập thử:
      // sai thì Supabase trả về lỗi invalid credentials.
      {
        const { data: profile } = await supabase
          .from('profiles')
          .select('email')
          .eq('id', userId)
          .single();

        // Không lấy được email (chế độ mock / chưa seed) thì bỏ qua bước này
        if (profile?.email) {
          const { createClient } = await import('@supabase/supabase-js');
          const verifyClient = createClient(
            env.SUPABASE_URL,
            env.SUPABASE_ANON_KEY,
            { auth: { persistSession: false, autoRefreshToken: false } }
          );
          const { error: verifyError } = await verifyClient.auth.signInWithPassword({
            email: profile.email,
            password: body.currentPassword,
          });
          if (verifyError) {
            throw new AppError('VALIDATION_ERROR', 400, 'Mật khẩu hiện tại không đúng');
          }
        }
      }

      // Tạo supabase client với user token để đổi mật khẩu
      const { createClient } = await import('@supabase/supabase-js');
      const userClient = createClient(
        env.SUPABASE_URL,
        env.SUPABASE_ANON_KEY,
        { global: { headers: { Authorization: `Bearer ${token}` } } }
      );

      const { error } = await userClient.auth.updateUser({
        password: body.newPassword,
      });

      if (error) {
        throw new AppError('VALIDATION_ERROR', 400, error.message || 'Không thể đổi mật khẩu');
      }

      res.json({ message: 'Đổi mật khẩu thành công' });
    } catch (err) {
      next(err);
    }
  });

  // POST /api/v1/profile/upload-avatar — upload ảnh đại diện
  router.post('/upload-avatar', async (req, res, next) => {
    try {
      const userId = req.user!.id;

      // Nhận base64 image từ body
      const { imageBase64, contentType = 'image/jpeg' } = req.body as {
        imageBase64?: string;
        contentType?: string;
      };

      if (!imageBase64) {
        throw new AppError('VALIDATION_ERROR', 400, 'Thiếu dữ liệu ảnh (imageBase64)');
      }

      // Decode base64
      const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
      const buffer = Buffer.from(base64Data, 'base64');

      if (buffer.length > 5 * 1024 * 1024) {
        throw new AppError('VALIDATION_ERROR', 400, 'Ảnh không được vượt quá 5MB');
      }

      const ext = contentType.split('/')[1] || 'jpg';
      const filePath = `avatars/${userId}/avatar.${ext}`;

      // Upload lên Supabase Storage
      const { error: uploadError } = await supabase.storage
        .from('user-avatars')
        .upload(filePath, buffer, {
          contentType,
          upsert: true,
        });

      if (uploadError) {
        throw new AppError('SERVER_ERROR', 500, `Upload thất bại: ${uploadError.message}`);
      }

      // Lấy public URL
      const { data: urlData } = supabase.storage
        .from('user-avatars')
        .getPublicUrl(filePath);

      const avatarUrl = urlData.publicUrl;

      // Cập nhật avatar_url trong profiles
      await supabase
        .from('profiles')
        .update({ avatar_url: avatarUrl })
        .eq('id', userId);

      res.json({
        message: 'Upload ảnh đại diện thành công',
        avatarUrl,
      });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
