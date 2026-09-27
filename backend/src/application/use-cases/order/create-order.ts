import { OrderRepository } from '../../../domain/repositories/order.repository.js';
import { CartRepository } from '../../../domain/repositories/cart.repository.js';
import { AppError } from '../../../domain/errors.js';
import { ShippingInfo, Order } from '../../../domain/entities/order.js';

export interface CreateOrderRequest {
  userId: string;
  ship: ShippingInfo;
  paymentMethod: 'cod' | 'vnpay';
  items?: Array<{ variantId: string; quantity: number }>;
  idempotencyKey?: string;
}

export class CreateOrder {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly cartRepo: CartRepository
  ) {}

  async execute(req: CreateOrderRequest): Promise<Order> {
    let items = req.items;

    // Neu khong truyen items, lay hang tu gio cua user tren server
    if (!items || items.length === 0) {
      const cart = await this.cartRepo.getByUserId(req.userId);
      if (!cart.items || cart.items.length === 0) {
        throw new AppError('EMPTY_CART', 400, 'Giỏ hàng của bạn đang trống');
      }
      items = cart.items.map((i) => ({
        variantId: i.variantId,
        quantity: i.quantity,
      }));
    }

    try {
      const orderId = await this.orderRepo.create({
        userId: req.userId,
        items,
        ship: req.ship,
        paymentMethod: req.paymentMethod,
        shippingFee: 0,
        idempotencyKey: req.idempotencyKey,
      });

      const order = await this.orderRepo.findById(orderId);
      if (!order) {
        throw new AppError('INTERNAL', 500, 'Không tìm thấy đơn hàng sau khi tạo');
      }
      return order;
    } catch (err: unknown) {
      if (err instanceof AppError) throw err;
      const message = err instanceof Error ? err.message : String(err);
      if (message.includes('OUT_OF_STOCK')) {
        throw new AppError('OUT_OF_STOCK', 409, 'Một số sản phẩm trong giỏ đã hết hàng hoặc không đủ số lượng');
      }
      throw err;
    }
  }
}
