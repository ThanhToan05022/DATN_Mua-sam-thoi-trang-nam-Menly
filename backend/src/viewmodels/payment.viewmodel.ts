import { AppError } from '../models/types.js';
import { IOrderModel } from '../models/order.model.js';
import { IPaymentModel } from '../models/payment.model.js';
import { PaymentGateway } from '../application/ports/payment-gateway.js';

export interface CreatePaymentInput {
  orderId: string;
  userId: string;
  clientIp: string;
}

export interface IpnResponse {
  RspCode: string;
  Message: string;
}

export class PaymentViewModel {
  constructor(
    private readonly orderModel: IOrderModel,
    private readonly paymentModel: IPaymentModel,
    private readonly gateway: PaymentGateway
  ) {}

  async createPaymentUrl(i: CreatePaymentInput): Promise<{ paymentUrl: string; txnRef: string }> {
    const order = await this.orderModel.findById(i.orderId);
    if (!order) throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    if (order.userId !== i.userId) throw new AppError('FORBIDDEN', 403, 'Không có quyền truy cập');
    if (order.status !== 'pending_payment') {
      throw new AppError('ORDER_NOT_PAYABLE', 409, `Đơn hàng ở trạng thái ${order.status}, không thể thanh toán`);
    }

    const txnRef = `${order.code}_${Date.now()}`;
    const expireAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.paymentModel.createPending({
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

  async handleIpn(query: Record<string, string>): Promise<IpnResponse> {
    const isValid = this.gateway.verify(query);
    if (!isValid) return { RspCode: '97', Message: 'Invalid Checksum' };

    const txnRef = query.vnp_TxnRef;
    if (!txnRef) return { RspCode: '01', Message: 'Order not found' };

    const payment = await this.paymentModel.findByTxnRef(txnRef);
    if (!payment) return { RspCode: '01', Message: 'Order not found' };

    const vnpAmount = Number(query.vnp_Amount) / 100;
    if (vnpAmount !== payment.amount) return { RspCode: '04', Message: 'Invalid amount' };
    if (payment.status !== 'pending') return { RspCode: '02', Message: 'Order already confirmed' };

    const isSuccess = query.vnp_ResponseCode === '00';
    await this.paymentModel.settle({
      txnRef,
      success: isSuccess,
      txnNo: query.vnp_TransactionNo,
      bankCode: query.vnp_BankCode,
      responseCode: query.vnp_ResponseCode,
      raw: query,
    });

    return { RspCode: '00', Message: 'Confirm Success' };
  }
}
