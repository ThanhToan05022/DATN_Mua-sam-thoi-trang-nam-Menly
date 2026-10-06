import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { apiLogger } from '../presentation/http/middlewares/logger.middleware.js';
import { createRequireAuth, requireAdmin, requireCustomer, requireStaffOrAdmin } from '../presentation/http/middlewares/auth.js';
import { errorHandler, notFound } from '../presentation/http/middlewares/error-handler.js';
import {
  generalRateLimit,
  orderRateLimit,
  trackOrderRateLimit,
} from '../presentation/http/middlewares/rate-limit.js';

import { healthRoutes } from '../presentation/http/routes/health.routes.js';
import { categoryRoutes } from './routes/category.routes.js';
import { productRoutes } from './routes/product.routes.js';
import { cartRoutes } from './routes/cart.routes.js';
import { orderRoutes } from './routes/order.routes.js';
import { paymentRoutes } from './routes/payment.routes.js';
import { adminRoutes } from './routes/admin.routes.js';
import { authRoutes } from './routes/auth.routes.js';
import { userRoutes } from './routes/user.routes.js';
import { profileRoutes } from './routes/profile.routes.js';
import { wishlistRoutes } from './routes/wishlist.routes.js';
import { voucherRoutes, adminVoucherRoutes } from './routes/voucher.routes.js';
import { reviewRoutes } from './routes/review.routes.js';

import { viewModels, supabase, userModel } from '../container.js';

export function createApp(): Express {
  const app = express();
  app.set('trust proxy', 1);

  // Global Middlewares
  app.use(apiLogger);
  app.use(
    helmet({
      crossOriginResourcePolicy: false,
    })
  );
  app.use(
    cors({
      origin: true,
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'x-user-email', 'x-user-id'],
    })
  );
  app.use(generalRateLimit);
  app.use(express.json({ limit: '100kb' }));
  app.use(express.urlencoded({ extended: true }));

  const requireAuth = createRequireAuth(supabase);

  // Health routes
  app.use('/health', healthRoutes(supabase));
  app.use('/api/v1/health', healthRoutes(supabase));

  // MVVM View Routes
  app.use('/api/v1/categories', categoryRoutes(viewModels.category));
  app.use('/api/v1/products', productRoutes(viewModels.product));
  app.use('/api/v1/cart', cartRoutes(requireAuth, viewModels.cart));
  app.use(
    '/api/v1/orders',
    orderRoutes(
      requireAuth,
      { order: orderRateLimit, track: trackOrderRateLimit },
      viewModels.order,
      requireCustomer
    )
  );
  app.use('/api/v1/payments', paymentRoutes(requireAuth, viewModels.payment));
  app.use(
    '/api/v1/admin/users',
    userRoutes(requireAuth, requireAdmin, viewModels.user)
  );
  app.use(
    '/api/v1/admin/vouchers',
    adminVoucherRoutes(requireAuth, requireStaffOrAdmin, viewModels.voucher)
  );
  app.use(
    '/api/v1/admin',
    adminRoutes(requireAuth, requireAdmin, viewModels.admin, viewModels.product, requireStaffOrAdmin, viewModels.review)
  );
  app.use('/api/v1/profile', profileRoutes(requireAuth, supabase, userModel));
  app.use('/api/v1/wishlist', wishlistRoutes(requireAuth, viewModels.wishlist));
  app.use('/api/v1/vouchers', voucherRoutes(viewModels.voucher));
  app.use('/api/v1/reviews', reviewRoutes(requireAuth, viewModels.review));

  app.use('/api/v1/auth', authRoutes(viewModels.auth, requireAuth, requireAdmin, userModel));

  // 404 & Error Handlers
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
