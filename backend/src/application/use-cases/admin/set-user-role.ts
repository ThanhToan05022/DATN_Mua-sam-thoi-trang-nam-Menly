import { AdminRepository } from '../../../domain/repositories/admin.repository.js';
import { AppError } from '../../../domain/errors.js';

export class SetUserRole {
  constructor(private readonly repo: AdminRepository) {}

  async execute(userId: string, role: 'customer' | 'admin'): Promise<void> {
    if (role !== 'customer' && role !== 'admin') {
      throw new AppError('INVALID_ROLE', 400, 'Vai trò không hợp lệ');
    }
    await this.repo.setUserRole(userId, role);
  }
}
