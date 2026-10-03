import { Order, OrderStatus } from '../../../domain/entities/order.js';
import { Page } from '../../../domain/pagination.js';
import { OrderRepository } from '../../../domain/repositories/order.repository.js';
import { decodeCursor, encodeCursor } from '../../cursor.js';

export interface ListAdminOrdersInput {
  limit: number;
  status?: OrderStatus;
  cursor?: string;
  fromDate?: string;
  toDate?: string;
  day?: string;
}

export class ListAdminOrders {
  constructor(private readonly repo: OrderRepository) {}

  async execute(i: ListAdminOrdersInput): Promise<Page<Order>> {
    const orders = await this.repo.listAll(
      i.limit + 1,
      i.status,
      i.cursor ? decodeCursor(i.cursor) : undefined,
      i.fromDate || i.toDate || i.day ? { fromDate: i.fromDate, toDate: i.toDate, day: i.day } : undefined
    );

    const hasNext = orders.length > i.limit;
    const items = hasNext ? orders.slice(0, i.limit) : orders;
    const last = items.at(-1);

    return {
      items,
      pageInfo: {
        limit: i.limit,
        hasNext,
        nextCursor:
          hasNext && last
            ? encodeCursor({ v: last.createdAt, id: last.id })
            : null,
      },
    };
  }
}
