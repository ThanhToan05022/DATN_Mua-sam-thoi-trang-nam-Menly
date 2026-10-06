import { Request, Response, NextFunction, RequestHandler } from 'express';
import { SupabaseClient } from '@supabase/supabase-js';
import { AppError } from '../../../domain/errors.js';

export interface AuthUser {
  id: string;
  role: 'customer' | 'admin' | 'guest';
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

      // Ho tro mock user trong moi truong dev / testing
      if (token.startsWith('mock-admin-') || token === 'admin-token') {
        req.user = { id: '00000000-0000-0000-0000-000000000001', role: 'admin' };
        return next();
      }
      if (token.startsWith('mock-user-') || token === 'user-token') {
        req.user = { id: '00000000-0000-0000-0000-000000000002', role: 'customer' };
        return next();
      }
      if (token.startsWith('mock-guest-') || token === 'guest-token') {
        req.user = { id: '00000000-0000-0000-0000-000000000003', role: 'guest' };
        return next();
      }

      if (!supabase) {
        throw new AppError('UNAUTHORIZED', 401, 'Supabase auth service is not configured');
      }

      const { data, error } = await supabase.auth.getUser(token);
      if (error || !data.user) {
        throw new AppError('UNAUTHORIZED', 401, 'Token không hợp lệ hoặc đã hết hạn');
      }

      const isAnonymous = (data.user as { is_anonymous?: boolean }).is_anonymous ?? false;
      const appRole = data.user.app_metadata?.role as 'admin' | 'customer' | undefined;

      req.user = {
        id: data.user.id,
        role: isAnonymous ? 'guest' : appRole === 'admin' ? 'admin' : 'customer',
      };

      next();
    } catch (err) {
      next(err);
    }
  };
};

export const requireAdmin: RequestHandler = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  if (req.user?.role !== 'admin') {
    throw new AppError('FORBIDDEN', 403, 'Yêu cầu quyền quản trị (Admin)');
  }
  next();
};

// Block guest (anonymous) users - chỉ cho phép customer và admin thật
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
