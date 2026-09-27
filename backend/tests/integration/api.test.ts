import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/views/app.js';

describe('MenShop API Integration Tests (MVVM Architecture)', () => {
  const app = createApp();
  const userToken = 'Bearer mock-user-123';
  const adminToken = 'Bearer mock-admin-123';

  it('GET /health - should return 200 and healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('OK');
  });

  it('GET /api/v1/categories - should list all categories via CategoryViewModel', async () => {
    const res = await request(app).get('/api/v1/categories');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  it('GET /api/v1/products - should return cursor paginated products via ProductViewModel', async () => {
    const res = await request(app).get('/api/v1/products?limit=2&sort=newest');
    expect(res.status).toBe(200);
    expect(res.body.items).toBeDefined();
    expect(res.body.pageInfo).toBeDefined();
    expect(res.body.items.length).toBeLessThanOrEqual(2);
  });

  it('GET /api/v1/products/:id - should return single product detail', async () => {
    const res = await request(app).get('/api/v1/products/a0000000-0000-0000-0000-000000000001');
    expect(res.status).toBe(200);
    expect(res.body.id).toBe('a0000000-0000-0000-0000-000000000001');
    expect(res.body.variants).toBeDefined();
  });

  it('Cart flow: PUT /api/v1/cart/items and GET /api/v1/cart via CartViewModel', async () => {
    const putRes = await request(app)
      .put('/api/v1/cart/items')
      .set('Authorization', userToken)
      .send({
        variantId: 'v1111111-1111-1111-1111-111111111111',
        quantity: 2,
      });

    expect(putRes.status).toBe(200);
    expect(putRes.body.totalItems).toBe(2);

    const getRes = await request(app)
      .get('/api/v1/cart')
      .set('Authorization', userToken);

    expect(getRes.status).toBe(200);
    expect(getRes.body.items.length).toBe(1);
    expect(getRes.body.items[0].variantId).toBe('v1111111-1111-1111-1111-111111111111');
  });

  it('Order flow: POST /api/v1/orders and GET /api/v1/orders/track via OrderViewModel', async () => {
    const orderRes = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', userToken)
      .send({
        ship: {
          name: 'Nguyen Van A',
          phone: '0901234567',
          address: '123 Nguyen Trai, Ha Noi',
        },
        paymentMethod: 'cod',
      });

    expect(orderRes.status).toBe(201);
    expect(orderRes.body.id).toBeDefined();
    expect(orderRes.body.code).toBeDefined();

    const orderCode = orderRes.body.code;

    const trackRes = await request(app)
      .get(`/api/v1/orders/track?code=${orderCode}&phone=0901234567`);

    expect(trackRes.status).toBe(200);
    expect(trackRes.body.code).toBe(orderCode);
    expect(trackRes.body.status).toBe('processing');
  });

  it('Payment flow: POST /api/v1/payments/vnpay/create via PaymentViewModel', async () => {
    const orderRes = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', userToken)
      .send({
        items: [{ variantId: 'v1111111-1111-1111-1111-111111111112', quantity: 1 }],
        ship: {
          name: 'Tran Van B',
          phone: '0912345678',
          address: '456 Le Loi, TP HCM',
        },
        paymentMethod: 'vnpay',
      });

    expect(orderRes.status).toBe(201);
    const orderId = orderRes.body.id;

    const payRes = await request(app)
      .post('/api/v1/payments/vnpay/create')
      .set('Authorization', userToken)
      .send({ orderId });

    expect(payRes.status).toBe(200);
    expect(payRes.body.paymentUrl).toContain('sandbox.vnpayment.vn');
    expect(payRes.body.txnRef).toBeDefined();
  });

  it('Admin authorization check: /api/v1/admin/orders via AdminViewModel', async () => {
    const forbiddenRes = await request(app)
      .get('/api/v1/admin/orders')
      .set('Authorization', userToken);
    expect(forbiddenRes.status).toBe(403);

    const adminRes = await request(app)
      .get('/api/v1/admin/orders')
      .set('Authorization', adminToken);
    expect(adminRes.status).toBe(200);
  });

  it('POST /api/v1/auth/login - should authenticate valid user', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@menshop.vn', password: 'Admin@123456' });

    expect(res.status).toBe(200);
    expect(res.body.user).toBeDefined();
    expect(res.body.user.role).toBe('admin');
    expect(res.body.accessToken).toBeDefined();
  });

  it('POST /api/v1/auth/login - lockout ladder: 5 failed attempts locks for 5 mins with 423 & Retry-After', async () => {
    const email = 'lockout-test@menshop.vn';

    // 4 wrong attempts -> 401
    for (let i = 1; i <= 4; i++) {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email, password: 'wrong-password' });
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
      expect(res.body.error.details.remainingAttempts).toBe(5 - i);
    }

    // 5th wrong attempt -> 423 Locked with Retry-After header
    const lockRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: 'wrong-password' });
    expect(lockRes.status).toBe(423);
    expect(lockRes.body.error.code).toBe('ACCOUNT_LOCKED');
    expect(lockRes.headers['retry-after']).toBe('300');
    expect(lockRes.body.error.details.lockoutMinutes).toBe(5);

    // Status check
    const statusRes = await request(app).get(`/api/v1/auth/status?email=${email}`);
    expect(statusRes.status).toBe(200);
    expect(statusRes.body.isLocked).toBe(true);
    expect(statusRes.body.retryAfterSeconds).toBeGreaterThan(0);
  });
});
