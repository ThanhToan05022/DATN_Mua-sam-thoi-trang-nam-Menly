import { describe, it, expect, beforeEach } from 'vitest';
import { UserModel } from '../../src/models/user.model.js';
import { UserViewModel } from '../../src/viewmodels/user.viewmodel.js';
import { AuthModel } from '../../src/models/auth.model.js';
import { AuthViewModel } from '../../src/viewmodels/auth.viewmodel.js';

describe('User Management & Authentication Tests', () => {
  let userModel: UserModel;
  let userVm: UserViewModel;
  let authModel: AuthModel;
  let authVm: AuthViewModel;

  beforeEach(() => {
    userModel = new UserModel();
    userVm = new UserViewModel(userModel);
    authModel = new AuthModel(undefined, userModel);
    authVm = new AuthViewModel(authModel);
  });

  it('Default admin admin@gmail.com with 123456 should log in successfully', async () => {
    const session = await authVm.login('admin@gmail.com', '123456');
    expect(session.user.email).toBe('admin@gmail.com');
    expect(session.user.role).toBe('admin');
    expect(session.accessToken).toBeTruthy();
  });

  it('Register API: should register new user and allow login', async () => {
    const regSession = await authVm.register(
      'Tran Thi B',
      'tranthib@gmail.com',
      'password123',
      'user'
    );
    expect(regSession.user.email).toBe('tranthib@gmail.com');

    const loginSession = await authVm.login('tranthib@gmail.com', 'password123');
    expect(loginSession.user.email).toBe('tranthib@gmail.com');
  });

  it('Locking user: locked account should be blocked from logging in', async () => {
    const customer = await userModel.createUser({
      name: 'Khách Hàng Test',
      email: 'customertest@gmail.com',
      password: 'password123',
      role: 'user',
    });

    // Lock account
    await userVm.toggleLockUser(customer.id, true);

    // Attempt login should throw error
    await expect(authVm.login('customertest@gmail.com', 'password123')).rejects.toThrow(
      'Tài khoản của bạn đã bị khoá'
    );

    // Unlock account
    await userVm.toggleLockUser(customer.id, false);
    const session = await authVm.login('customertest@gmail.com', 'password123');
    expect(session.user.email).toBe('customertest@gmail.com');
  });

  it('Cannot delete or lock default admin admin@gmail.com', async () => {
    const users = await userVm.listUsers();
    const admin = users.find((u) => u.email === 'admin@gmail.com');
    expect(admin).toBeDefined();

    await expect(userVm.deleteUser(admin!.id)).rejects.toThrow(
      'Không thể xóa tài khoản Admin mặc định'
    );

    await expect(userVm.toggleLockUser(admin!.id, true)).rejects.toThrow(
      'Không thể khóa tài khoản Admin mặc định'
    );
  });
});
