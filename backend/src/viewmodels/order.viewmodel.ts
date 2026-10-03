import { Order, Page, ShippingInfo, AppError } from '../models/types.js';
import { IOrderModel, TrackOrderResult } from '../models/order.model.js';
import { ICartModel } from '../models/cart.model.js';
import { IVoucherModel } from '../models/voucher.model.js';
import { decodeCursor, encodeCursor } from './base.viewmodel.js';

export interface CreateOrderRequest {
  userId: string;
  userEmail?: string;
  ship: ShippingInfo;
  paymentMethod: 'cod' | 'vnpay';
  items?: Array<{ variantId: string; quantity: number }>;
  idempotencyKey?: string;
  note?: string;
  voucherCode?: string;
  discountAmount?: number;
}

export class OrderViewModel {
  constructor(
    private readonly orderModel: IOrderModel,
    private readonly cartModel: ICartModel,
    private readonly voucherModel?: IVoucherModel
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

    let discountAmount = req.discountAmount || 0;
    if (req.voucherCode && this.voucherModel) {
      try {
        let estimatedSubtotal = 0;
        for (const item of items) {
          estimatedSubtotal += (item as any).unitPrice
            ? (item as any).unitPrice * item.quantity
            : 350000 * item.quantity;
        }
        const calc = await this.voucherModel.validateAndCalculate(req.voucherCode, estimatedSubtotal);
        discountAmount = calc.discountAmount;
        await this.voucherModel.incrementUsage(req.voucherCode);
      } catch (err: any) {
        if (!discountAmount) {
          throw err;
        }
      }
    }

    const orderId = await this.orderModel.create({
      userId: req.userId,
      userEmail: req.userEmail,
      items,
      ship: req.ship,
      paymentMethod: req.paymentMethod,
      shippingFee: 0,
      idempotencyKey: req.idempotencyKey,
      note: req.note,
      voucherCode: req.voucherCode,
      discountAmount,
    });

    const order = await this.orderModel.findById(orderId);
    if (!order) {
      throw new AppError('INTERNAL', 500, 'Không tìm thấy đơn hàng sau khi tạo');
    }

    // Dọn dẹp các món đã đặt khỏi giỏ hàng trên server
    try {
      for (const item of items) {
        await this.cartModel.removeItem(req.userId, item.variantId);
      }
    } catch (err) {
      console.warn('Could not clear ordered items from cartModel:', err);
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

  async listMyOrders(
    userId: string,
    limit: number,
    cursor?: string,
    userEmail?: string,
    headerUserId?: string
  ): Promise<Page<Order>> {
    const orders = await this.orderModel.listByUser(
      userId,
      limit + 1,
      cursor ? decodeCursor(cursor) : undefined,
      userEmail,
      headerUserId
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

  async cancelOrder(
    orderId: string,
    userId: string,
    note?: string,
    userEmail?: string,
    headerUserId?: string
  ): Promise<Order> {
    const order = await this.orderModel.findById(orderId);
    if (!order) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    }

    const isOwner =
      order.userId === userId ||
      (headerUserId && order.userId === headerUserId) ||
      (userEmail && order.userEmail && order.userEmail.toLowerCase().trim() === userEmail.toLowerCase().trim());

    if (!isOwner) {
      throw new AppError('FORBIDDEN', 403, 'Bạn không có quyền huỷ đơn hàng này');
    }

    if (order.status === 'cancelled') {
      throw new AppError('ORDER_ALREADY_CANCELLED', 400, 'Đơn hàng đã ở trạng thái ĐÃ HUỶ');
    }

    if (order.status === 'shipping' || order.status === 'completed') {
      throw new AppError('CANNOT_CANCEL', 400, 'Đơn hàng đang giao hoặc đã hoàn thành, không thể huỷ');
    }

    await this.orderModel.updateStatus(order.id, 'cancelled', note || 'Khách hàng huỷ đơn');
    const updated = await this.orderModel.findById(order.id);
    return updated || order;
  }

  async trackOrder(code: string, phone: string): Promise<TrackOrderResult> {
    const res = await this.orderModel.trackByCodeAndPhone(code.trim(), phone.trim());
    if (!res) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Không tìm thấy đơn hàng với thông tin đã cung cấp');
    }
    return res;
  }
}
