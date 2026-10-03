import { Order } from '../../../domain/entities/order.js';
import { OrderRepository } from '../../../domain/repositories/order.repository.js';
import { AppError } from '../../../domain/errors.js';

export class GetOrder {
  constructor(private readonly repo: OrderRepository) {}

  async execute(orderId: string, userId: string, isAdmin = false): Promise<Order> {
    const order = await this.repo.findById(orderId);
    if (!order) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    }

    if (!isAdmin && order.userId !== userId) {
      throw new AppError('FORBIDDEN', 403, 'Bạn không có quyền xem đơn hàng này');
    }

    return order;
  }
}
