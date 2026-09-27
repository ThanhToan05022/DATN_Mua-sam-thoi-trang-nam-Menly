import { Order, Page, ShippingInfo, AppError } from '../models/types.js';
import { IOrderModel, TrackOrderResult } from '../models/order.model.js';
import { ICartModel } from '../models/cart.model.js';
import { decodeCursor, encodeCursor } from './base.viewmodel.js';

export interface CreateOrderRequest {
  userId: string;
  ship: ShippingInfo;
  paymentMethod: 'cod' | 'vnpay';
  items?: Array<{ variantId: string; quantity: number }>;
  idempotencyKey?: string;
}

export class OrderViewModel {
  constructor(
    private readonly orderModel: IOrderModel,
    private readonly cartModel: ICartModel
  ) {}

  async createOrder(req: CreateOrderRequest): Promise<Order> {
    let items = req.items;

    // Lay tu gio tren server neu khong truyen items
    if (!items || items.length === 0) {
      const cart = await this.cartModel.getByUserId(req.userId);
      if (!cart.items || cart.items.length === 0) {
        throw new AppError('EMPTY_CART', 400, 'Giỏ hàng của bạn đang trống');
      }
      items = cart.items.map((i) => ({
        variantId: i.variantId,
        quantity: i.quantity,
      }));
    }

    const orderId = await this.orderModel.create({
      userId: req.userId,
      items,
      ship: req.ship,
      paymentMethod: req.paymentMethod,
      shippingFee: 0,
      idempotencyKey: req.idempotencyKey,
    });

    const order = await this.orderModel.findById(orderId);
    if (!order) {
      throw new AppError('INTERNAL', 500, 'Không tìm thấy đơn hàng sau khi tạo');
    }
    return order;
  }

  async getOrder(orderId: string, userId: string, isAdmin = false): Promise<Order> {
    const order = await this.orderModel.findById(orderId);
    if (!order) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    }
    if (!isAdmin && order.userId !== userId) {
      throw new AppError('FORBIDDEN', 403, 'Bạn không có quyền xem đơn hàng này');
    }
    return order;
  }

  async listMyOrders(userId: string, limit: number, cursor?: string): Promise<Page<Order>> {
    const orders = await this.orderModel.listByUser(
      userId,
      limit + 1,
      cursor ? decodeCursor(cursor) : undefined
    );

    const hasNext = orders.length > limit;
    const items = hasNext ? orders.slice(0, limit) : orders;
    const last = items.at(-1);

    return {
      items,
      pageInfo: {
        limit,
        hasNext,
        nextCursor:
          hasNext && last
            ? encodeCursor({ v: last.createdAt, id: last.id })
            : null,
      },
    };
  }

  async trackOrder(code: string, phone: string): Promise<TrackOrderResult> {
    const res = await this.orderModel.trackByCodeAndPhone(code.trim(), phone.trim());
    if (!res) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Không tìm thấy đơn hàng với thông tin đã cung cấp');
    }
    return res;
  }
}
