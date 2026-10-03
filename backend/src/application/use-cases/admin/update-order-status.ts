import { AdminRepository } from '../../../domain/repositories/admin.repository.js';
import { OrderStatus } from '../../../domain/entities/order.js';

export interface UpdateOrderStatusInput {
  orderId: string;
  status: OrderStatus;
  note?: string;
  adminId: string;
}

export class UpdateOrderStatus {
  constructor(private readonly repo: AdminRepository) {}

  async execute(i: UpdateOrderStatusInput): Promise<void> {
    await this.repo.updateOrderStatus(i.orderId, i.status, i.note, i.adminId);
  }
}
