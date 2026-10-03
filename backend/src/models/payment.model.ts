import { SupabaseClient } from '@supabase/supabase-js';
import { Payment, PaymentStatus, AppError } from './types.js';

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

export interface IPaymentModel {
  createPending(input: CreatePaymentRecord): Promise<Payment>;
  findByTxnRef(txnRef: string): Promise<Payment | null>;
  settle(input: SettlePaymentInput): Promise<'ok' | 'already' | 'not_found'>;
}

export class PaymentModel implements IPaymentModel {
  private inMemoryPayments: Payment[] = [];

  constructor(private readonly supabase?: SupabaseClient) {}

  async createPending(input: CreatePaymentRecord): Promise<Payment> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('payments')
        .insert({
          order_id: input.orderId,
          txn_ref: input.txnRef,
          amount: input.amount,
          status: 'pending',
        })
        .select()
        .single();

      if (error || !data) throw new AppError('DB_PAYMENT_CREATE_FAILED', 500, error?.message);
      return {
        id: data.id,
        orderId: data.order_id,
        provider: 'vnpay',
        txnRef: data.txn_ref,
        amount: data.amount,
        status: data.status as PaymentStatus,
        createdAt: data.created_at,
      };
    }

    const p: Payment = {
      id: `pay-${Date.now()}`,
      orderId: input.orderId,
      provider: 'vnpay',
      txnRef: input.txnRef,
      amount: input.amount,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };
    this.inMemoryPayments.push(p);
    return p;
  }

  async findByTxnRef(txnRef: string): Promise<Payment | null> {
    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('payments')
        .select('id, order_id, txn_ref, amount, status, provider_txn_no, bank_code, response_code, raw, created_at, paid_at')
        .eq('txn_ref', txnRef)
        .maybeSingle();

      if (error) throw new AppError('DB_PAYMENT_QUERY_FAILED', 500, error.message);
      if (!data) return null;

      return {
        id: data.id,
        orderId: data.order_id,
        provider: 'vnpay',
        txnRef: data.txn_ref,
        amount: data.amount,
        status: data.status as PaymentStatus,
        providerTxnNo: data.provider_txn_no,
        bankCode: data.bank_code,
        responseCode: data.response_code,
        raw: data.raw,
        createdAt: data.created_at,
        paidAt: data.paid_at,
      };
    }

    return this.inMemoryPayments.find((p) => p.txnRef === txnRef) || null;
  }

  async settle(input: SettlePaymentInput): Promise<'ok' | 'already' | 'not_found'> {
    if (this.supabase) {
      const { data, error } = await this.supabase.rpc('settle_payment', {
        p_txn_ref: input.txnRef,
        p_success: input.success,
        p_txn_no: input.txnNo || null,
        p_bank: input.bankCode || null,
        p_code: input.responseCode || null,
        p_raw: input.raw || null,
      });

      if (error) throw new AppError('DB_SETTLE_PAYMENT_FAILED', 500, error.message);
      if (data === 'already') return 'already';
      if (data === 'ok') return 'ok';
      return 'not_found';
    }

    const p = this.inMemoryPayments.find((pay) => pay.txnRef === input.txnRef);
    if (!p) return 'not_found';
    if (p.status !== 'pending') return 'already';

    p.status = input.success ? 'success' : 'failed';
    p.paidAt = input.success ? new Date().toISOString() : null;
    p.providerTxnNo = input.txnNo;
    p.bankCode = input.bankCode;
    p.responseCode = input.responseCode;
    p.raw = input.raw;
    return 'ok';
  }
}
