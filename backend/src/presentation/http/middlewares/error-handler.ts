import { ErrorRequestHandler, RequestHandler } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../../../domain/errors.js';

export const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
  if (err instanceof ZodError) {
    res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Dữ liệu không hợp lệ',
        details: err.issues.map((i) => ({
          path: i.path.join('.'),
          message: i.message,
        })),
      },
    });
    return;
  }

  if (err instanceof AppError) {
    res.status(err.status).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
    });
    return;
  }

  if (process.env.NODE_ENV !== 'test') {
    console.error(`  \x1b[31m[API Error]\x1b[0m ${req.method} ${req.originalUrl || req.path}:`, err?.message || err);
    if (process.env.NODE_ENV !== 'production' && err?.stack) {
      console.error(err.stack);
    }
  }

  res.status(500).json({
    error: {
      code: 'INTERNAL',
      message: 'Lỗi hệ thống nội bộ',
    },
  });
};

export const notFound: RequestHandler = (req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: `Đường dẫn ${req.method} ${req.path} không tồn tại`,
    },
  });
};
