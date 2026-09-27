export interface VnpayConfig {
  tmnCode: string;
  hashSecret: string;
  payUrl: string;
  returnUrl: string;
}

export interface PaymentUrlParams {
  txnRef: string;
  amountVnd: number;
  ip: string;
  orderInfo: string;
  expireAt: Date;
}

export interface PaymentGateway {
  buildPaymentUrl(params: PaymentUrlParams): string;
  verify(query: Record<string, string>): boolean;
}
