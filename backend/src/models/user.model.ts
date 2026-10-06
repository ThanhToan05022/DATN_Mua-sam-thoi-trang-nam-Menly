import { SupabaseClient } from '@supabase/supabase-js';
import { AppError } from './types.js';

export interface UserAccount {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'user';
  isLocked: boolean;
  createdAt: string;
  password?: string;
}

export interface IUserModel {
  listUsers(): Promise<UserAccount[]>;
  getUserById(id: string): Promise<UserAccount | null>;
  getUserByEmail(email: string): Promise<UserAccount | null>;
  createUser(data: {
    name: string;
    email: string;
    password?: string;
    role?: 'admin' | 'user';
  }): Promise<UserAccount>;
  updateUser(
    id: string,
    data: { name?: string; email?: string; role?: 'admin' | 'user' }
  ): Promise<UserAccount>;
  deleteUser(id: string): Promise<boolean>;
  setLockStatus(id: string, isLocked: boolean): Promise<UserAccount>;
}

export class UserModel implements IUserModel {
  private users: UserAccount[] = [
    {
      id: 'usr-admin-001',
      name: 'Admin MenShop',
      email: 'admin@gmail.com',
      password: '123456',
      role: 'admin',
      isLocked: false,
      createdAt: '2026-01-01T08:00:00.000Z',
    },
  ];

  constructor(private readonly supabase?: SupabaseClient) {}

  async listUsers(): Promise<UserAccount[]> {
    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('profiles')
          .select('id, full_name, email, role, is_locked, created_at')
          .order('created_at', { ascending: false });
        if (!error && data && data.length > 0) {
          return data.map((r: any) => ({
            id: r.id,
            name: r.full_name || 'Người dùng',
            email: r.email || `${r.id.slice(0, 8)}@menshop.vn`,
            role: r.role === 'admin' ? 'admin' : 'user',
            isLocked: Boolean(r.is_locked),
            createdAt: r.created_at,
          }));
        }
      } catch {
        // Fallback to in-memory
      }
    }

    return this.users.map((u) => {
      const { password, ...safe } = u;
      return safe as UserAccount;
    });
  }

  async getUserById(id: string): Promise<UserAccount | null> {
    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('profiles')
          .select('id, full_name, email, role, is_locked, created_at')
          .eq('id', id)
          .maybeSingle();
        if (!error && data) {
          const mem = this.users.find((u) => u.id === id);
          return {
            id: data.id,
            name: data.full_name || 'Người dùng',
            email: data.email || '',
            role: data.role === 'admin' ? 'admin' : 'user',
            isLocked: Boolean(data.is_locked),
            createdAt: data.created_at,
            password: mem?.password,
          };
        }
      } catch {
        // Fallback to in-memory
      }
    }

    const user = this.users.find((u) => u.id === id);
    return user || null;
  }

  async getUserByEmail(email: string): Promise<UserAccount | null> {
    const normalized = email.toLowerCase().trim();
    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('profiles')
          .select('id, full_name, email, role, is_locked, created_at')
          .eq('email', normalized)
          .maybeSingle();
        if (!error && data) {
          const mem = this.users.find((u) => u.email.toLowerCase().trim() === normalized);
          return {
            id: data.id,
            name: data.full_name || 'Người dùng',
            email: data.email || normalized,
            role: data.role === 'admin' ? 'admin' : 'user',
            isLocked: Boolean(data.is_locked),
            createdAt: data.created_at,
            password: mem?.password || (normalized === 'admin@gmail.com' ? '123456' : undefined),
          };
        }
      } catch {
        // Fallback to in-memory
      }
    }

    const user = this.users.find((u) => u.email.toLowerCase().trim() === normalized);
    return user || null;
  }

  async createUser(data: {
    name: string;
    email: string;
    password?: string;
    role?: 'admin' | 'user';
  }): Promise<UserAccount> {
    const normalized = data.email.toLowerCase().trim();
    const existing = await this.getUserByEmail(normalized);
    if (existing) {
      throw new AppError('EMAIL_EXISTS', 400, 'Email này đã được sử dụng');
    }

    const newUser: UserAccount = {
      id: `usr-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      name: data.name.trim(),
      email: normalized,
      password: data.password || '123456',
      role: data.role || 'user',
      isLocked: false,
      createdAt: new Date().toISOString(),
    };

    if (this.supabase) {
      try {
        await this.supabase.from('profiles').insert({
          id: newUser.id,
          email: newUser.email,
          full_name: newUser.name,
          role: newUser.role,
          is_locked: false,
        });
      } catch {
        // Ignore and rely on memory
      }
    }

    this.users.unshift(newUser);
    const { password, ...safe } = newUser;
    return safe as UserAccount;
  }

  async updateUser(
    id: string,
    data: { name?: string; email?: string; role?: 'admin' | 'user' }
  ): Promise<UserAccount> {
    const user = this.users.find((u) => u.id === id);
    if (!user) {
      throw new AppError('USER_NOT_FOUND', 404, 'Không tìm thấy người dùng');
    }

    if (data.email && data.email.toLowerCase().trim() !== user.email.toLowerCase().trim()) {
      const normalized = data.email.toLowerCase().trim();
      const existing = await this.getUserByEmail(normalized);
      if (existing && existing.id !== id) {
        throw new AppError('EMAIL_EXISTS', 400, 'Email này đã được sử dụng bởi người dùng khác');
      }
      user.email = normalized;
    }

    if (data.name) user.name = data.name.trim();
    if (data.role) user.role = data.role;

    if (this.supabase) {
      try {
        const patch: Record<string, unknown> = {};
        if (data.name) patch.full_name = data.name.trim();
        if (data.email) patch.email = data.email.toLowerCase().trim();
        if (data.role) patch.role = data.role;
        await this.supabase.from('profiles').update(patch).eq('id', id);
      } catch {
        // Ignore
      }
    }

    const { password, ...safe } = user;
    return safe as UserAccount;
  }

  async deleteUser(id: string): Promise<boolean> {
    const index = this.users.findIndex((u) => u.id === id);
    if (index === -1) {
      throw new AppError('USER_NOT_FOUND', 404, 'Không tìm thấy người dùng');
    }

    if (this.users[index].email === 'admin@gmail.com') {
      throw new AppError('CANNOT_DELETE_PRIMARY_ADMIN', 400, 'Không thể xóa tài khoản Admin mặc định');
    }

    if (this.supabase) {
      try {
        await this.supabase.from('profiles').delete().eq('id', id);
      } catch {
        // Ignore
      }
    }

    this.users.splice(index, 1);
    return true;
  }

  async setLockStatus(id: string, isLocked: boolean): Promise<UserAccount> {
    const user = this.users.find((u) => u.id === id);
    if (!user) {
      throw new AppError('USER_NOT_FOUND', 404, 'Không tìm thấy người dùng');
    }

    if (user.email === 'admin@gmail.com' && isLocked) {
      throw new AppError('CANNOT_LOCK_PRIMARY_ADMIN', 400, 'Không thể khóa tài khoản Admin mặc định');
    }

    user.isLocked = isLocked;

    if (this.supabase) {
      try {
        await this.supabase
          .from('profiles')
          .update({ is_locked: isLocked })
          .eq('id', id);
      } catch {
        // Ignore
      }
    }

    const { password, ...safe } = user;
    return safe as UserAccount;
  }
}
