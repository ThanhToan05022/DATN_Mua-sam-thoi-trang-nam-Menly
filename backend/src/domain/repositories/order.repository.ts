import { Order, OrderStatus, ShippingInfo } from '../entities/order.js';
import { Cursor } from '../pagination.js';

export interface CreateOrderInput {
  userId: string;
  items: Array<{ variantId: string; quantity: number }>;
  ship: ShippingInfo;
  paymentMethod: 'cod' | 'vnpay';
  shippingFee: number;
  idempotencyKey?: string;
}

export interface TrackOrderResult {
  id: string;
  code: string;
  status: OrderStatus;
  total: number;
  paymentMethod: string;
  createdAt: string;
  items: Array<{
    productName: string;
    size: string;
    color: string;
    quantity: number;
    unitPrice: number;
  }>;
}

export interface OrderRepository {
  create(input: CreateOrderInput): Promise<string>;
  findById(id: string): Promise<Order | null>;
  listByUser(userId: string, limit: number, cursor?: Cursor): Promise<Order[]>;
  listAll(
    limit: number,
    status?: OrderStatus,
    cursor?: Cursor,
    dateFilter?: { fromDate?: string; toDate?: string; day?: string }
  ): Promise<Order[]>;
  trackByCodeAndPhone(code: string, phone: string): Promise<TrackOrderResult | null>;
}
