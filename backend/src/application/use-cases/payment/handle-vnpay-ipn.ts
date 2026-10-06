import { PaymentRepository } from '../../../domain/repositories/payment.repository.js';
import { PaymentGateway } from '../../ports/payment-gateway.js';

export interface IpnResult {
  RspCode: string;
  Message: string;
}

export class HandleVnpayIpn {
  constructor(
    private readonly paymentRepo: PaymentRepository,
    private readonly gateway: PaymentGateway
  ) {}

  async execute(query: Record<string, string>): Promise<IpnResult> {
    const isValidSignature = this.gateway.verify(query);
    if (!isValidSignature) {
      return { RspCode: '97', Message: 'Invalid Checksum' };
    }

    const txnRef = query.vnp_TxnRef;
    if (!txnRef) {
      return { RspCode: '01', Message: 'Order not found' };
    }

    const payment = await this.paymentRepo.findByTxnRef(txnRef);
    if (!payment) {
      return { RspCode: '01', Message: 'Order not found' };
    }

    const vnpAmount = Number(query.vnp_Amount) / 100;
    if (vnpAmount !== payment.amount) {
      return { RspCode: '04', Message: 'Invalid amount' };
    }

    if (payment.status !== 'pending') {
      return { RspCode: '02', Message: 'Order already confirmed' };
    }

    const isSuccess = query.vnp_ResponseCode === '00';
    await this.paymentRepo.settle({
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
