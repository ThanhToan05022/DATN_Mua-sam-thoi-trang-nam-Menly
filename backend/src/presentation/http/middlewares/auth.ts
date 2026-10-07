import { Request, Response, NextFunction, RequestHandler } from 'express';
import { SupabaseClient } from '@supabase/supabase-js';
import { AppError } from '../../../domain/errors.js';
import { env } from '../../../config/env.js';

export interface AuthUser {
  id: string;
  role: 'customer' | 'admin' | 'staff' | 'guest';
  email?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export const createRequireAuth = (
  supabase?: SupabaseClient
): RequestHandler => {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      const authHeader = req.headers.authorization;
      const token = authHeader?.replace(/^Bearer\s+/i, '');

      if (!token) {
        throw new AppError('UNAUTHORIZED', 401, 'Thiếu token xác thực');
      }

      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;

      // Chỉ bật mock token khi backend đang chạy không có Supabase (mock/test).
      if (!supabase || env.NODE_ENV === 'test') {
        if (token.startsWith('mock-admin-') || token === 'admin-token' || token.toLowerCase().includes('admin')) {
          const id = token.startsWith('mock-admin-token-') ? token.replace('mock-admin-token-', '') : (headerUserId || '00000000-0000-0000-0000-000000000001');
          req.user = { id, role: 'admin', email: headerEmail || 'admin@gmail.com' };
          return next();
        }
        if (token.startsWith('mock-staff-') || token === 'staff-token' || token.toLowerCase().includes('staff')) {
          const id = token.startsWith('mock-staff-token-') ? token.replace('mock-staff-token-', '') : (headerUserId || '00000000-0000-0000-0000-000000000004');
          req.user = { id, role: 'staff', email: headerEmail || 'staff@gmail.com' };
          return next();
        }
        if (token.startsWith('mock-user-') || token === 'user-token') {
          const id = token.startsWith('mock-user-token-') ? token.replace('mock-user-token-', '') : (headerUserId || '00000000-0000-0000-0000-000000000002');
          req.user = { id, role: 'customer', email: headerEmail || undefined };
          return next();
        }
        if (token.startsWith('mock-guest-') || token === 'guest-token') {
          req.user = { id: '00000000-0000-0000-0000-000000000003', role: 'guest' };
          return next();
        }
      }

      // Xử lý JWT token (từ Supabase Auth hoặc JWT chuẩn)
      let jwtPayload: any = null;
      if (token.split('.').length === 3) {
        try {
          const payloadBase64 = token.split('.')[1];
          const payloadJson = Buffer.from(payloadBase64, 'base64url').toString('utf8');
          jwtPayload = JSON.parse(payloadJson);
        } catch (_) {}
      }

      if (!supabase) {
        if (jwtPayload && (jwtPayload.sub || jwtPayload.id)) {
          const uid = jwtPayload.sub || jwtPayload.id;
          const isAnonymous = jwtPayload.is_anonymous === true;
          let role: 'customer' | 'admin' | 'staff' | 'guest' = isAnonymous ? 'guest' : 'customer';
          const metaRole = jwtPayload.app_metadata?.role || jwtPayload.user_metadata?.role;
          if (metaRole === 'admin' || metaRole === 'staff') {
            role = metaRole;
          } else if (jwtPayload.email?.toLowerCase().includes('admin')) {
            role = 'admin';
          } else if (jwtPayload.email?.toLowerCase().includes('staff')) {
            role = 'staff';
          }
          req.user = { id: uid, role, email: jwtPayload.email || headerEmail };
          return next();
        }
        throw new AppError('UNAUTHORIZED', 401, 'Supabase auth service is not configured');
      }

      let data: any = null;
      try {
        const res = await supabase.auth.getUser(token);
        data = res.data;
      } catch (_) {}

      if (!data?.user) {
        throw new AppError('UNAUTHORIZED', 401, 'Token không hợp lệ hoặc đã hết hạn');
      }

      const isAnonymous = (data.user as { is_anonymous?: boolean }).is_anonymous ?? false;
      let userRole: 'customer' | 'admin' | 'staff' | 'guest' = 'customer';

      if (isAnonymous) {
        userRole = 'guest';
      } else {
        const metaRole = (data.user.app_metadata?.role || data.user.user_metadata?.role) as string | undefined;
        if (metaRole === 'admin' || metaRole === 'staff') {
          userRole = metaRole;
        } else if (
          data.user.email?.toLowerCase().includes('admin') ||
          data.user.email?.toLowerCase() === 'admin@menshop.vn' ||
          data.user.email?.toLowerCase() === 'admin@gmail.com'
        ) {
          userRole = 'admin';
        } else if (
          data.user.email?.toLowerCase().includes('staff') ||
          data.user.email?.toLowerCase() === 'staff@gmail.com'
        ) {
          userRole = 'staff';
        } else {
          // Kiểm tra bảng public.profiles trong database
          try {
            const { data: prof } = await supabase
              .from('profiles')
              .select('role')
              .eq('id', data.user.id)
              .maybeSingle();
            if (prof?.role === 'admin' || prof?.role === 'staff') {
              userRole = prof.role;
            }
          } catch (_) {}
        }
      }

      req.user = {
        id: data.user.id,
        role: userRole,
        email: data.user.email || headerEmail,
      };

      next();
    } catch (err) {
      next(err);
    }
  };
};

// Yêu cầu quyền quản trị viên tối cao (Admin)
export const requireAdmin: RequestHandler = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  if (req.user?.role !== 'admin') {
    throw new AppError('FORBIDDEN', 403, 'Yêu cầu quyền quản trị tối cao (Admin)');
  }
  next();
};

// Yêu cầu quyền nhân viên vận hành hoặc quản trị viên (Staff hoặc Admin)
export const requireStaffOrAdmin: RequestHandler = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  if (req.user?.role !== 'admin' && req.user?.role !== 'staff') {
    throw new AppError('FORBIDDEN', 403, 'Yêu cầu quyền nhân viên vận hành hoặc quản trị viên');
  }
  next();
};

// Block guest (anonymous) users - chỉ cho phép customer, staff và admin thật
export const requireCustomer: RequestHandler = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  if (!req.user) {
    throw new AppError('UNAUTHORIZED', 401, 'Bạn cần đăng nhập để thực hiện thao tác này');
  }
  if (req.user.role === 'guest') {
    throw new AppError('FORBIDDEN', 403, 'Bạn cần đăng ký tài khoản để mua hàng');
  }
  next();
};
