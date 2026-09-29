import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import pino from 'pino';

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

import { viewModels, supabase } from '../container.js';

export function createApp(): Express {
  const app = express();
  const logger = pino({
    level: process.env.NODE_ENV === 'test' ? 'silent' : 'info',
    redact: ['req.headers.authorization', 'req.query.vnp_SecureHash'],
  });

  app.set('trust proxy', 1);

  // Global Middlewares
  app.use(pinoHttp({ logger }));
  app.use(helmet());
  app.use(cors());
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
    '/api/v1/admin',
    adminRoutes(requireAuth, requireAdmin, viewModels.admin, viewModels.product, requireStaffOrAdmin)
  );
  app.use('/api/v1/profile', profileRoutes(requireAuth, supabase));
  app.use('/api/v1/wishlist', wishlistRoutes(requireAuth, viewModels.wishlist));

  app.use('/api/v1/auth', authRoutes(viewModels.auth, requireAuth, requireAdmin));

  // 404 & Error Handlers
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
