import { IUserModel, UserAccount } from '../models/user.model.js';
import { AppError } from '../models/types.js';

export class UserViewModel {
  constructor(private readonly userModel: IUserModel) {}

  async listUsers(): Promise<UserAccount[]> {
    return this.userModel.listUsers();
  }

  async getUserById(id: string): Promise<UserAccount> {
    const user = await this.userModel.getUserById(id);
    if (!user) {
      throw new AppError('USER_NOT_FOUND', 404, 'Không tìm thấy người dùng');
    }
    return user;
  }

  async createUser(data: {
    name: string;
    email: string;
    password?: string;
    role?: 'admin' | 'user';
  }): Promise<UserAccount> {
    if (!data.name || !data.email) {
      throw new AppError('VALIDATION_ERROR', 400, 'Tên và email là bắt buộc');
    }
    return this.userModel.createUser(data);
  }

  async updateUser(
    id: string,
    data: { name?: string; email?: string; role?: 'admin' | 'user' }
  ): Promise<UserAccount> {
    return this.userModel.updateUser(id, data);
  }

  async deleteUser(id: string): Promise<{ success: boolean; message: string }> {
    await this.userModel.deleteUser(id);
    return { success: true, message: 'Đã xóa người dùng thành công' };
  }

  async toggleLockUser(id: string, isLocked: boolean): Promise<UserAccount> {
    return this.userModel.setLockStatus(id, isLocked);
  }
}
