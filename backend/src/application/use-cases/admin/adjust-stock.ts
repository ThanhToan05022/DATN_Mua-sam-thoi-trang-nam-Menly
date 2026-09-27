import { AdminRepository } from '../../../domain/repositories/admin.repository.js';
import { InventoryMovementReason } from '../../../domain/entities/admin.js';
import { AppError } from '../../../domain/errors.js';

export interface AdjustStockInput {
  variantId: string;
  delta: number;
  reason: 'admin_restock' | 'admin_correction';
  note?: string;
  adminId: string;
}

export class AdjustStock {
  constructor(private readonly repo: AdminRepository) {}

  async execute(i: AdjustStockInput): Promise<{ newStock: number }> {
    if (i.reason !== 'admin_restock' && i.reason !== 'admin_correction') {
      throw new AppError('INVALID_REASON', 400, 'Lý do điều chỉnh không hợp lệ');
    }

    const newStock = await this.repo.adjustStock(
      i.variantId,
      i.delta,
      i.reason as InventoryMovementReason,
      i.note,
      i.adminId
    );

    return { newStock };
  }
}
