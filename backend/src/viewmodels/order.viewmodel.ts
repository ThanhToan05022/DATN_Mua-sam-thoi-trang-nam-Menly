import {
  Order,
  OrderStatus,
  OrderStatusHistoryEntry,
  OrderTimelineStep,
  Page,
  ShippingInfo,
  AppError,
} from '../models/types.js';
import { IOrderModel, TrackOrderResult } from '../models/order.model.js';
import { ICartModel } from '../models/cart.model.js';
import { IVoucherModel } from '../models/voucher.model.js';
import { decodeCursor, encodeCursor } from './base.viewmodel.js';
import { AddressViewModel } from './address.viewmodel.js';
import { resolveUserUuid } from '../shared/user-identity.js';

export interface CreateOrderRequest {
  userId: string;
  userEmail?: string;
  ship?: ShippingInfo;
  /** Chọn địa chỉ đã lưu — server tự dựng thông tin giao hàng từ địa chỉ này */
  addressId?: string;
  paymentMethod: 'cod' | 'vnpay';
  items?: Array<{ variantId: string; quantity: number }>;
  idempotencyKey?: string;
  note?: string;
  voucherCode?: string;
  discountAmount?: number;
}

/** Nhãn tiếng Việt cho từng trạng thái đơn hàng */
const STATUS_LABELS: Record<OrderStatus, string> = {
  pending_payment: 'Đã đặt hàng',
  paid: 'Đã thanh toán',
  processing: 'Đã xác nhận',
  shipping: 'Đang giao hàng',
  completed: 'Hoàn tất',
  cancelled: 'Đã huỷ',
};

const STATUS_DESCRIPTIONS: Record<OrderStatus, string> = {
  pending_payment: 'Đơn hàng đã được ghi nhận, đang chờ thanh toán',
  paid: 'Thanh toán thành công, cửa hàng sẽ xử lý',
  processing: 'Cửa hàng đã xác nhận và đang chuẩn bị hàng',
  shipping: 'Đơn hàng đang trên đường giao đến bạn',
  completed: 'Đơn hàng đã giao thành công. Cảm ơn bạn!',
  cancelled: 'Đơn hàng đã bị huỷ',
};

/**
 * Luồng trạng thái chuẩn để dựng timeline khi bảng lịch sử trạng thái rỗng
 * (đơn cũ hoặc môi trường chưa ghi được history).
 */
const HAPPY_PATH: OrderStatus[] = [
  'pending_payment',
  'processing',
  'shipping',
  'completed',
];

const buildTimeline = (
  status: OrderStatus,
  history: OrderStatusHistoryEntry[],
  createdAt: string
): OrderTimelineStep[] => {
  const byStatus = new Map<OrderStatus, OrderStatusHistoryEntry>();
  for (const entry of history) {
    if (!byStatus.has(entry.status)) byStatus.set(entry.status, entry);
  }

  if (status === 'cancelled') {
    const placedAt = byStatus.get('pending_payment')?.createdAt ?? createdAt;
    const cancelledAt = byStatus.get('cancelled')?.createdAt ?? createdAt;
    return [
      {
        status: 'pending_payment',
        label: STATUS_LABELS.pending_payment,
        description: STATUS_DESCRIPTIONS.pending_payment,
        createdAt: placedAt,
        note: byStatus.get('pending_payment')?.note ?? null,
        completed: true,
        current: false,
      },
      {
        status: 'cancelled',
        label: STATUS_LABELS.cancelled,
        description: STATUS_DESCRIPTIONS.cancelled,
        createdAt: cancelledAt,
        note: byStatus.get('cancelled')?.note ?? null,
        completed: true,
        current: true,
      },
    ];
  }

  // Luôn hiển thị đủ vòng đời (Đã đặt → Xác nhận → Đang giao → Hoàn tất),
  // các bước chưa tới sẽ được đánh dấu completed = false.
  // 'paid' nằm ngoài luồng chuẩn nhưng vẫn là một mốc đáng hiển thị.
  const flow: OrderStatus[] = [...HAPPY_PATH];
  let currentIndex = HAPPY_PATH.indexOf(status);

  if (currentIndex < 0) {
    if (status === 'paid') {
      flow.splice(1, 0, 'paid');
      currentIndex = 1;
    } else {
      currentIndex = 0;
    }
  }

  return flow.map((step, index) => {
    const entry = byStatus.get(step);
    const reached = index <= currentIndex;
    return {
      status: step,
      label: STATUS_LABELS[step],
      description: STATUS_DESCRIPTIONS[step],
      createdAt:
        entry?.createdAt ?? (reached && index === 0 ? createdAt : null),
      note: entry?.note ?? null,
      completed: reached,
      current: index === currentIndex,
    };
  });
};

export class OrderViewModel {
  constructor(
    private readonly orderModel: IOrderModel,
    private readonly cartModel: ICartModel,
    private readonly voucherModel?: IVoucherModel,
    private readonly addressViewModel?: AddressViewModel
  ) {}

  /**
   * Chốt thông tin giao hàng: ưu tiên địa chỉ đã lưu (addressId),
   * nếu không thì dùng khối ship gửi kèm. Cho phép nhập tay khi không có cả hai.
   */
  private async resolveShip(req: CreateOrderRequest): Promise<ShippingInfo> {
    if (req.addressId) {
      if (!this.addressViewModel) {
        throw new AppError(
          'ADDRESS_SERVICE_UNAVAILABLE',
          503,
          'Tính năng địa chỉ giao hàng đang tạm thời không khả dụng'
        );
      }
      return this.addressViewModel.resolveShipping(
        req.userId,
        req.addressId,
        req.userEmail
      );
    }

    if (req.ship) return req.ship;

    // Không truyền gì: lấy địa chỉ mặc định của tài khoản
    if (this.addressViewModel) {
      const fallback = await this.addressViewModel.getDefault(
        req.userId,
        req.userEmail
      );
      if (fallback) {
        return {
          name: fallback.recipientName,
          phone: fallback.phone,
          address: [
            fallback.detailAddress,
            fallback.ward,
            fallback.district,
            fallback.province,
          ]
            .filter((part) => part && part.trim().length > 0)
            .join(', '),
        };
      }
    }

    throw new AppError(
      'SHIPPING_INFO_REQUIRED',
      400,
      'Vui lòng chọn địa chỉ giao hàng hoặc nhập thông tin nhận hàng'
    );
  }

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

    const ship = await this.resolveShip(req);

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
      ship,
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

    return this.withTimeline(order);
  }

  /** Gắn lịch sử trạng thái + timeline dựng sẵn vào đơn hàng */
  private async withTimeline(order: Order): Promise<Order> {
    let history = order.statusHistory ?? [];
    if (!history || history.length === 0) {
      try {
        history = await this.orderModel.getStatusHistory(order.id);
      } catch (err) {
        console.warn('Could not load order status history:', err);
        history = [];
      }
    }
    return {
      ...order,
      statusHistory: history,
      timeline: buildTimeline(order.status, history, order.createdAt),
    };
  }

  async getOrder(
    orderId: string,
    userId: string,
    isAdmin = false,
    userEmail?: string
  ): Promise<Order> {
    const order = await this.orderModel.findById(orderId);
    if (!order) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    }

    // `order.userId` là uuid trong DB còn `userId` từ token có thể là id giả lập,
    // nên phải chuẩn hoá cả hai về cùng một dạng trước khi so sánh.
    if (!isAdmin) {
      // `order.userId` là uuid trong DB còn id từ token có thể là id giả lập,
      // nên so sánh cả dạng thô lẫn dạng đã chuẩn hoá.
      const requester = new Set<string>();
      if (userId?.trim()) requester.add(userId.trim());
      const normalizedRequester = resolveUserUuid(userId, userEmail);
      if (normalizedRequester) requester.add(normalizedRequester);

      const owner = new Set<string>();
      if (order.userId) owner.add(order.userId);
      const normalizedOwner = resolveUserUuid(order.userId);
      if (normalizedOwner) owner.add(normalizedOwner);

      const owns = [...requester].some((id) => owner.has(id));
      if (!owns) {
        throw new AppError(
          'FORBIDDEN',
          403,
          'Bạn không có quyền xem đơn hàng này'
        );
      }
    }

    return this.withTimeline(order);
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
    return this.withTimeline(updated || order);
  }

  async trackOrder(code: string, phone: string): Promise<TrackOrderResult> {
    const res = await this.orderModel.trackByCodeAndPhone(code.trim(), phone.trim());
    if (!res) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Không tìm thấy đơn hàng với thông tin đã cung cấp');
    }
    return res;
  }
}
