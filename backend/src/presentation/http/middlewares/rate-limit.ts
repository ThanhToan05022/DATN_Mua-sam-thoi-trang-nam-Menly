import rateLimit from 'express-rate-limit';

export const generalRateLimit = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: {
      code: 'RATE_LIMITED',
      message: 'Quá nhiều yêu cầu, vui lòng thử lại sau giây lát',
    },
  },
});

export const orderRateLimit = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: {
      code: 'RATE_LIMITED',
      message: 'Thao tác đặt hàng quá nhanh, vui lòng thử lại sau',
    },
  },
});

export const trackOrderRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 15,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: {
      code: 'RATE_LIMITED',
      message: 'Tra cứu quá nhiều lần, vui lòng thử lại sau 1 giờ',
    },
  },
});
