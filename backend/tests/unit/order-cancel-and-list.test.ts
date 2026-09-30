import { describe, it, expect, beforeEach } from 'vitest';
import { OrderModel } from '../../src/models/order.model.js';
import { OrderViewModel } from '../../src/viewmodels/order.viewmodel.js';
import { ICartModel } from '../../src/models/cart.model.js';

describe('Order Model & ViewModel: Order display & cancellation', () => {
  let orderModel: OrderModel;
  let orderViewModel: OrderViewModel;
  const mockCartModel: ICartModel = {
    getByUserId: async (uid: string) => ({ items: [], totalItems: 0, subtotal: 0 }),
    addItem: async () => {},
    updateItem: async () => {},
    removeItem: async () => {},
    clear: async () => {},
  };

  beforeEach(() => {
    orderModel = new OrderModel(undefined, [
      {
        id: 'ord-001',
        code: 'MS260930001',
        userId: 'usr-12345',
        userEmail: 'user@example.com',
        status: 'processing',
        paymentMethod: 'cod',
        subtotal: 500000,
        shippingFee: 0,
        total: 500000,
        shipName: 'Nguyen Van A',
        shipPhone: '0987654321',
        shipAddress: '123 Nguyen Trai, Ha Noi',
        createdAt: '2026-09-30T10:00:00.000Z',
        items: [],
      },
      {
        id: 'ord-002',
        code: 'MS260929002',
        userId: 'usr-12345',
        status: 'cancelled',
        paymentMethod: 'cod',
        subtotal: 700000,
        shippingFee: 0,
        total: 700000,
        shipName: 'Nguyen Van A',
        shipPhone: '0987654321',
        shipAddress: '123 Nguyen Trai, Ha Noi',
        note: 'Đã huỷ đơn hàng',
        createdAt: '2026-09-29T10:00:00.000Z',
        items: [],
      },
    ]);

    orderViewModel = new OrderViewModel(orderModel, mockCartModel);
  });

  it('should list both processing and cancelled orders even if user logs in with different ID but same email', async () => {
    // Supabase login produces a UUID, but email is 'user@example.com'
    const page = await orderViewModel.listMyOrders(
      'uuid-supabase-999',
      50,
      undefined,
      'user@example.com',
      'usr-12345'
    );

    expect(page.items.length).toBe(2);
    const codes = page.items.map((o) => o.code);
    expect(codes).toContain('MS260930001');
    expect(codes).toContain('MS260929002');

    const cancelledOrder = page.items.find((o) => o.code === 'MS260929002');
    expect(cancelledOrder?.status).toBe('cancelled');
    expect(cancelledOrder?.note).toBe('Đã huỷ đơn hàng');
  });

  it('should allow customer to cancel an order that is in processing status', async () => {
    const cancelled = await orderViewModel.cancelOrder(
      'ord-001',
      'usr-12345',
      'Thay đổi kích thước',
      'user@example.com'
    );

    expect(cancelled.status).toBe('cancelled');
    expect(cancelled.note).toBe('Thay đổi kích thước');

    // Verify it is updated in list
    const page = await orderViewModel.listMyOrders('usr-12345', 50);
    const order1 = page.items.find((o) => o.id === 'ord-001');
    expect(order1?.status).toBe('cancelled');
  });

  it('should prevent cancelling an already cancelled order', async () => {
    await expect(
      orderViewModel.cancelOrder('ord-002', 'usr-12345', 'Huỷ tiếp')
    ).rejects.toThrow();
  });
});
