export type PaymentStatus = 'pending' | 'success' | 'failed';

export interface Payment {
  id: string;
  orderId: string;
  provider: 'vnpay';
  txnRef: string;
  amount: number;
  status: PaymentStatus;
  providerTxnNo?: string | null;
  bankCode?: string | null;
  responseCode?: string | null;
  raw?: unknown;
  createdAt: string;
  paidAt?: string | null;
}
