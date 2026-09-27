import {
  PaymentGateway,
  PaymentUrlParams,
  VnpayConfig,
} from '../../application/ports/payment-gateway.js';
import { buildSignData, sign, verify, fmtVn } from './vnpay.sign.js';

export class VnpayGateway implements PaymentGateway {
  constructor(private readonly cfg: VnpayConfig) {}

  buildPaymentUrl(i: PaymentUrlParams): string {
    const params: Record<string, string | number> = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: this.cfg.tmnCode,
      vnp_Amount: i.amountVnd * 100,
      vnp_CurrCode: 'VND',
      vnp_TxnRef: i.txnRef,
      vnp_OrderInfo: i.orderInfo,
      vnp_OrderType: 'other',
      vnp_Locale: 'vn',
      vnp_ReturnUrl: this.cfg.returnUrl,
      vnp_IpAddr: i.ip,
      vnp_CreateDate: fmtVn(new Date()),
      vnp_ExpireDate: fmtVn(i.expireAt),
    };

    const data = buildSignData(params);
    const secureHash = sign(data, this.cfg.hashSecret);
    return `${this.cfg.payUrl}?${data}&vnp_SecureHash=${secureHash}`;
  }

  verify(query: Record<string, string>): boolean {
    return verify(query, this.cfg.hashSecret);
  }
}
