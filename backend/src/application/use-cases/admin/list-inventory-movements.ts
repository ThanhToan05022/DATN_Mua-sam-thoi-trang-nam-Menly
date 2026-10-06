import { InventoryMovement } from '../../../domain/entities/admin.js';
import { AdminRepository } from '../../../domain/repositories/admin.repository.js';

export class ListInventoryMovements {
  constructor(private readonly repo: AdminRepository) {}

  async execute(variantId?: string, limit = 50): Promise<InventoryMovement[]> {
    return this.repo.listInventoryMovements(variantId, limit);
  }
}
