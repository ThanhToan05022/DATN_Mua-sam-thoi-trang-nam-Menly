import { OrderRepository, TrackOrderResult } from '../../../domain/repositories/order.repository.js';
import { AppError } from '../../../domain/errors.js';

export class TrackOrder {
  constructor(private readonly repo: OrderRepository) {}

  async execute(code: string, phone: string): Promise<TrackOrderResult> {
    const result = await this.repo.trackByCodeAndPhone(code.trim(), phone.trim());
    if (!result) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Không tìm thấy đơn hàng với mã và số điện thoại đã cung cấp');
    }
    return result;
  }
}
