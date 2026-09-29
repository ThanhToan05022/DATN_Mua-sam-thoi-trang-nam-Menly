import { describe, it, expect, beforeEach } from 'vitest';
import { OrderModel } from '../../src/models/order.model.js';
import { AdminViewModel } from '../../src/viewmodels/admin.viewmodel.js';
import { AdminModel } from '../../src/models/admin.model.js';

describe('Admin Orders Date Filter Tests', () => {
  let orderModel: OrderModel;
  let adminModel: AdminModel;
  let adminVm: AdminViewModel;

  beforeEach(async () => {
    orderModel = new OrderModel();
    adminModel = new AdminModel();
    adminVm = new AdminViewModel(adminModel, orderModel);

    // Create mock orders with specific dates
    await orderModel.create({
      userId: 'usr-001',
      items: [{ variantId: 'v1', quantity: 2 }],
      ship: { name: 'Customer 1', phone: '0901234567', address: 'Hanoi' },
      paymentMethod: 'cod',
      shippingFee: 0,
      createdAt: '2026-09-20T10:00:00.000Z',
    });

    await orderModel.create({
      userId: 'usr-002',
      items: [{ variantId: 'v2', quantity: 1 }],
      ship: { name: 'Customer 2', phone: '0901234568', address: 'HCM' },
      paymentMethod: 'cod',
      shippingFee: 0,
      createdAt: '2026-09-25T14:30:00.000Z',
    });
  });

  it('Should filter orders by specific day', async () => {
    const page = await adminVm.listOrders(
      20,
      undefined,
      undefined,
      undefined,
      undefined,
      '2026-09-25'
    );
    expect(page.items.length).toBe(1);
    expect(page.items[0].createdAt.slice(0, 10)).toBe('2026-09-25');
  });

  it('Should filter orders by date range', async () => {
    const page = await adminVm.listOrders(
      20,
      undefined,
      undefined,
      '2026-09-19',
      '2026-09-21'
    );
    expect(page.items.length).toBe(1);
    expect(page.items[0].createdAt.slice(0, 10)).toBe('2026-09-20');
  });

  it('Should return all orders when no date filter specified', async () => {
    const page = await adminVm.listOrders(20);
    expect(page.items.length).toBe(2);
  });

  it('Should not allow changing status when order is cancelled', async () => {
    const page = await adminVm.listOrders(20);
    const orderId = page.items[0].id;

    // Change to cancelled
    await adminVm.updateOrderStatus(orderId, 'cancelled');
    const cancelledOrder = await orderModel.findById(orderId);
    expect(cancelledOrder?.status).toBe('cancelled');

    // Attempting to change to any other status must throw ORDER_ALREADY_CANCELLED
    await expect(adminVm.updateOrderStatus(orderId, 'shipping')).rejects.toThrow(
      'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác'
    );
    await expect(adminVm.updateOrderStatus(orderId, 'completed')).rejects.toThrow(
      'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác'
    );
  });
});

