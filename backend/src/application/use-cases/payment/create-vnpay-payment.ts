import { OrderRepository } from '../../../domain/repositories/order.repository.js';
import { PaymentRepository } from '../../../domain/repositories/payment.repository.js';
import { PaymentGateway } from '../../ports/payment-gateway.js';
import { AppError } from '../../../domain/errors.js';

export interface CreatePaymentInput {
  orderId: string;
  userId: string;
  clientIp: string;
}

export interface CreatePaymentOutput {
  paymentUrl: string;
  txnRef: string;
}

export class CreateVnpayPayment {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly paymentRepo: PaymentRepository,
    private readonly gateway: PaymentGateway
  ) {}

  async execute(i: CreatePaymentInput): Promise<CreatePaymentOutput> {
    const order = await this.orderRepo.findById(i.orderId);
    if (!order) {
      throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    }

    if (order.userId !== i.userId) {
      throw new AppError('FORBIDDEN', 403, 'Bạn không có quyền thanh toán đơn hàng này');
    }

    if (order.status !== 'pending_payment') {
      throw new AppError('ORDER_NOT_PAYABLE', 409, `Đơn hàng ở trạng thái ${order.status}, không thể thanh toán`);
    }

    const txnRef = `${order.code}_${Date.now()}`;
    const expireAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.paymentRepo.createPending({
      orderId: order.id,
      txnRef,
      amount: order.total,
    });

    const paymentUrl = this.gateway.buildPaymentUrl({
      txnRef,
      amountVnd: order.total,
      ip: i.clientIp,
      orderInfo: `Thanh toan don hang ${order.code}`,
      expireAt,
    });

    return { paymentUrl, txnRef };
  }
}
