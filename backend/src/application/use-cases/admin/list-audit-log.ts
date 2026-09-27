import { AdminAuditLog } from '../../../domain/entities/admin.js';
import { AdminRepository } from '../../../domain/repositories/admin.repository.js';

export class ListAuditLog {
  constructor(private readonly repo: AdminRepository) {}

  async execute(limit = 50): Promise<AdminAuditLog[]> {
    return this.repo.listAuditLogs(limit);
  }
}
