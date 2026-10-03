import { SupabaseClient } from '@supabase/supabase-js';
import { Payment, PaymentStatus } from '../../domain/entities/payment.js';
import {
  PaymentRepository,
  CreatePaymentRecord,
  SettlePaymentInput,
} from '../../domain/repositories/payment.repository.js';
import { InfraError } from '../../domain/errors.js';

export class SupabasePaymentRepository implements PaymentRepository {
  constructor(private readonly db: SupabaseClient) {}

  async createPending(input: CreatePaymentRecord): Promise<Payment> {
    const { data, error } = await this.db
      .from('payments')
      .insert({
        order_id: input.orderId,
        txn_ref: input.txnRef,
        amount: input.amount,
        status: 'pending',
      })
      .select()
      .single();

    if (error || !data) {
      throw new InfraError('DB_PAYMENT_CREATE_FAILED', error);
    }

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

  async findByTxnRef(txnRef: string): Promise<Payment | null> {
    const { data, error } = await this.db
      .from('payments')
      .select('id, order_id, txn_ref, amount, status, provider_txn_no, bank_code, response_code, raw, created_at, paid_at')
      .eq('txn_ref', txnRef)
      .maybeSingle();

    if (error) {
      throw new InfraError('DB_PAYMENT_QUERY_FAILED', error);
    }
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

  async settle(input: SettlePaymentInput): Promise<'ok' | 'already' | 'not_found'> {
    const { data, error } = await this.db.rpc('settle_payment', {
      p_txn_ref: input.txnRef,
      p_success: input.success,
      p_txn_no: input.txnNo || null,
      p_bank: input.bankCode || null,
      p_code: input.responseCode || null,
      p_raw: input.raw || null,
    });

    if (error) {
      throw new InfraError('DB_SETTLE_PAYMENT_RPC_FAILED', error);
    }

    if (data === 'already') return 'already';
    if (data === 'ok') return 'ok';
    return 'not_found';
  }
}
