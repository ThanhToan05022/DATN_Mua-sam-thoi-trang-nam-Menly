import { Payment } from '../entities/payment.js';

export interface CreatePaymentRecord {
  orderId: string;
  txnRef: string;
  amount: number;
}

export interface SettlePaymentInput {
  txnRef: string;
  success: boolean;
  txnNo?: string;
  bankCode?: string;
  responseCode?: string;
  raw?: unknown;
}

export interface PaymentRepository {
  createPending(input: CreatePaymentRecord): Promise<Payment>;
  findByTxnRef(txnRef: string): Promise<Payment | null>;
  settle(input: SettlePaymentInput): Promise<'ok' | 'already' | 'not_found'>;
}
