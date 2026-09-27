import { Order } from '../../../domain/entities/order.js';
import { Page } from '../../../domain/pagination.js';
import { OrderRepository } from '../../../domain/repositories/order.repository.js';
import { decodeCursor, encodeCursor } from '../../cursor.js';

export interface ListMyOrdersInput {
  userId: string;
  limit: number;
  cursor?: string;
}

export class ListMyOrders {
  constructor(private readonly repo: OrderRepository) {}

  async execute(i: ListMyOrdersInput): Promise<Page<Order>> {
    const orders = await this.repo.listByUser(
      i.userId,
      i.limit + 1,
      i.cursor ? decodeCursor(i.cursor) : undefined
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
