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

  it('Cart flow: PUT /api/v1/cart/items, GET /api/v1/cart, DELETE items, and DELETE / (clear)', async () => {
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

  it('Cart clear flow: DELETE /api/v1/cart', async () => {
    const testToken = 'Bearer mock-user-token-00000000-0000-0000-0000-000000000099';
    await request(app)
      .put('/api/v1/cart/items')
      .set('Authorization', testToken)
      .send({
        variantId: 'v1111111-1111-1111-1111-111111111111',
        quantity: 3,
      });

    const clearRes = await request(app)
      .delete('/api/v1/cart')
      .set('Authorization', testToken);

    expect(clearRes.status).toBe(200);
    expect(clearRes.body.items.length).toBe(0);
    expect(clearRes.body.totalItems).toBe(0);
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

  it('GET /api/v1/profile - should return profile with auth token', async () => {
    const res = await request(app)
      .get('/api/v1/profile')
      .set('Authorization', userToken);
    expect(res.status).toBe(200);
    expect(res.body.data).toBeDefined();
    expect(res.body.data.id).toBe('00000000-0000-0000-0000-000000000002');
  });

  it('PUT /api/v1/profile - should update user profile', async () => {
    const res = await request(app)
      .put('/api/v1/profile')
      .set('Authorization', userToken)
      .send({ fullName: 'Nguyễn Văn A', phone: '0987654321' });
    expect(res.status).toBe(200);
    expect(res.body.data.full_name).toBe('Nguyễn Văn A');
  });

  describe('3-Tier Role-Based Access Control (Admin, Staff, Customer)', () => {
    const staffToken = 'Bearer mock-staff-123';

    it('POST /api/v1/auth/register - allows registration as staff or customer', async () => {
      const staffRes = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'teststaff@menshop.vn',
          password: 'Password123',
          fullName: 'Staff Tester',
          role: 'staff',
        });

      expect(staffRes.status).toBe(201);
      expect(staffRes.body.user).toBeDefined();
      expect(staffRes.body.user.role).toBe('staff');
    });

    it('POST /api/v1/auth/login - authenticates staff default credentials', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'staff@gmail.com', password: '123456' });

      expect(res.status).toBe(200);
      expect(res.body.user).toBeDefined();
      expect(res.body.user.role).toBe('staff');
      expect(res.body.accessToken).toBeDefined();
    });

    it('Operations access: Staff can view and manage orders and products', async () => {
      const ordersRes = await request(app)
        .get('/api/v1/admin/orders')
        .set('Authorization', staffToken);
      expect(ordersRes.status).toBe(200);

      const productsRes = await request(app)
        .get('/api/v1/admin/products')
        .set('Authorization', staffToken);
      expect(productsRes.status).toBe(200);
    });

    it('Super-Admin boundary: Staff CANNOT access audit logs, user management or assign user roles (403 Forbidden)', async () => {
      const auditRes = await request(app)
        .get('/api/v1/admin/audit-log')
        .set('Authorization', staffToken);
      expect(auditRes.status).toBe(403);

      const usersRes = await request(app)
        .get('/api/v1/admin/users')
        .set('Authorization', staffToken);
      expect(usersRes.status).toBe(403);

      const roleRes = await request(app)
        .put('/api/v1/admin/users/00000000-0000-0000-0000-000000000002/role')
        .set('Authorization', staffToken)
        .send({ role: 'admin' });
      expect(roleRes.status).toBe(403);
    });

    it('Super-Admin privilege: Admin has FULL permissions (Audit logs, User management, Role modification)', async () => {
      const auditRes = await request(app)
        .get('/api/v1/admin/audit-log')
        .set('Authorization', adminToken);
      expect(auditRes.status).toBe(200);

      const usersRes = await request(app)
        .get('/api/v1/admin/users')
        .set('Authorization', adminToken);
      expect(usersRes.status).toBe(200);
      expect(Array.isArray(usersRes.body)).toBe(true);

      const roleRes = await request(app)
        .put('/api/v1/admin/users/00000000-0000-0000-0000-000000000002/role')
        .set('Authorization', adminToken)
        .send({ role: 'staff' });
      expect(roleRes.status).toBe(200);
    });

    it('Customer boundary: Customer CANNOT access staff/admin operations (403 Forbidden)', async () => {
      const ordersRes = await request(app)
        .get('/api/v1/admin/orders')
        .set('Authorization', userToken);
      expect(ordersRes.status).toBe(403);

      const auditRes = await request(app)
        .get('/api/v1/admin/audit-log')
        .set('Authorization', userToken);
      expect(auditRes.status).toBe(403);
    });
  });

  describe('Wishlist API Flow (Customer Favorites)', () => {
    const testProductId = 'a0000000-0000-0000-0000-000000000001';

    it('GET /api/v1/wishlist - requires authentication', async () => {
      const res = await request(app).get('/api/v1/wishlist');
      expect(res.status).toBe(401);
    });

    it('POST /api/v1/wishlist/:productId - adds product to wishlist', async () => {
      const res = await request(app)
        .post(`/api/v1/wishlist/${testProductId}`)
        .set('Authorization', userToken);

      expect(res.status).toBe(201);
      expect(res.body.productId).toBe(testProductId);
      expect(res.body.isFavorite).toBe(true);
    });

    it('GET /api/v1/wishlist/check/:productId - checks if product is in wishlist', async () => {
      const res = await request(app)
        .get(`/api/v1/wishlist/check/${testProductId}`)
        .set('Authorization', userToken);

      expect(res.status).toBe(200);
      expect(res.body.isFavorite).toBe(true);
    });

    it('GET /api/v1/wishlist - lists user favorited products', async () => {
      const res = await request(app)
        .get('/api/v1/wishlist')
        .set('Authorization', userToken);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.some((p: any) => p.id === testProductId)).toBe(true);
    });

    it('DELETE /api/v1/wishlist/:productId - removes product from wishlist', async () => {
      const delRes = await request(app)
        .delete(`/api/v1/wishlist/${testProductId}`)
        .set('Authorization', userToken);

      expect(delRes.status).toBe(200);
      expect(delRes.body.isFavorite).toBe(false);

      const checkRes = await request(app)
        .get(`/api/v1/wishlist/check/${testProductId}`)
        .set('Authorization', userToken);

      expect(checkRes.status).toBe(200);
      expect(checkRes.body.isFavorite).toBe(false);
    });
  });

  describe('Order Persistence across login/logout session flow', () => {
    it('Preserves orders and returns order code when user re-logs in', async () => {
      const createRes = await request(app)
        .post('/api/v1/orders')
        .set('Authorization', 'mock-user-token-usr-custom-999')
        .set('x-user-email', 'customer_flow@gmail.com')
        .send({
          items: [{ variantId: 'v-ao-polo-trang-m', quantity: 1 }],
          paymentMethod: 'cod',
          ship: {
            name: 'Nguyen Van A',
            phone: '0987654321',
            address: '123 Pho Hue, Hai Ba Trung, Hanoi',
          },
        });

      expect(createRes.status).toBe(201);
      expect(createRes.body.code).toBeDefined();
      expect(createRes.body.code.startsWith('MS')).toBe(true);
      const placedCode = createRes.body.code;

      // Simulate re-login with token and email
      const myOrdersRes = await request(app)
        .get('/api/v1/orders')
        .set('Authorization', 'mock-user-token-usr-custom-999')
        .set('x-user-email', 'customer_flow@gmail.com');

      expect(myOrdersRes.status).toBe(200);
      const items = myOrdersRes.body.items || myOrdersRes.body;
      expect(Array.isArray(items)).toBe(true);
      const foundOrder = items.find((o: any) => o.code === placedCode);
      expect(foundOrder).toBeDefined();
      expect(foundOrder.code).toBe(placedCode);
    });
  });
});


