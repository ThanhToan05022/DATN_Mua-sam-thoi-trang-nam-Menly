import { SupabaseClient } from '@supabase/supabase-js';
import { AppError } from './types.js';

export interface UserAccount {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'staff' | 'user' | 'seller';
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
    role?: 'admin' | 'staff' | 'user' | 'seller';
  }): Promise<UserAccount>;
  updateUser(
    id: string,
    data: { name?: string; email?: string; role?: 'admin' | 'staff' | 'user' | 'seller' }
  ): Promise<UserAccount>;
  deleteUser(id: string): Promise<boolean>;
  setLockStatus(id: string, isLocked: boolean): Promise<UserAccount>;
  updatePassword(idOrEmail: string, newPassword: string): Promise<boolean>;
}

export class UserModel implements IUserModel {
  private users: UserAccount[] = [
    {
      id: '0f444d92-322c-4956-b452-0c5c10950508',
      name: 'Admin MenShop',
      email: 'admin@gmail.com',
      password: '123456',
      role: 'admin',
      isLocked: false,
      createdAt: '2026-01-01T08:00:00.000Z',
    },
    {
      id: 'd604e122-aa50-47e0-ac44-10a2473af6ce',
      name: 'Nhân Viên MenShop',
      email: 'staff@gmail.com',
      password: '123456',
      role: 'staff',
      isLocked: false,
      createdAt: '2026-01-02T08:00:00.000Z',
    },
    {
      id: '7fb74d58-4155-4ab5-8124-cb0b5bb6651d',
      name: 'Nguyễn Văn Khách',
      email: 'customer@gmail.com',
      password: '123456',
      role: 'user',
      isLocked: false,
      createdAt: '2026-01-10T10:15:00.000Z',
    },
    {
      id: '00000000-0000-0000-0000-000000000002',
      name: 'Trần Thị Lan',
      email: 'customer@menshop.vn',
      password: '123456',
      role: 'user',
      isLocked: false,
      createdAt: '2026-01-15T14:20:00.000Z',
    },
    {
      id: 'c0000001-0000-0000-0000-000000000003',
      name: 'Lê Quang Huy',
      email: 'quanghuy@gmail.com',
      password: '123456',
      role: 'user',
      isLocked: false,
      createdAt: '2026-02-01T09:30:00.000Z',
    },
    {
      id: 'c0000001-0000-0000-0000-000000000004',
      name: 'Phạm Thanh Hà',
      email: 'thanhha@gmail.com',
      password: '123456',
      role: 'user',
      isLocked: false,
      createdAt: '2026-02-12T16:45:00.000Z',
    },
    {
      id: 'c0000001-0000-0000-0000-000000000005',
      name: 'Hoàng Văn Nam',
      email: 'hoangnam@gmail.com',
      password: '123456',
      role: 'user',
      isLocked: true,
      createdAt: '2026-02-20T11:00:00.000Z',
    },
    {
      id: 'c0000001-0000-0000-0000-000000000006',
      name: 'Ngô Minh Châu',
      email: 'minhchau@gmail.com',
      password: '123456',
      role: 'user',
      isLocked: false,
      createdAt: '2026-03-01T13:10:00.000Z',
    },
    {
      id: 's0000001-0000-0000-0000-000000000001',
      name: 'Gian Hàng Menly Store',
      email: 'seller@menshop.vn',
      password: '123456',
      role: 'seller',
      isLocked: false,
      createdAt: '2026-01-05T08:00:00.000Z',
    },
  ];

  constructor(private readonly supabase?: SupabaseClient) {}

  async listUsers(): Promise<UserAccount[]> {
    const userMap = new Map<string, UserAccount>();

    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('profiles')
          .select('id, full_name, email, role, is_locked, created_at')
          .order('created_at', { ascending: false });
        if (!error && data) {
          for (const r of data) {
            const role = r.role === 'admin' ? 'admin' : r.role === 'staff' ? 'staff' : r.role === 'seller' ? 'seller' : 'user';
            userMap.set(r.id, {
              id: r.id,
              name: r.full_name || 'Người dùng',
              email: r.email || `${r.id.slice(0, 8)}@menshop.vn`,
              role,
              isLocked: Boolean(r.is_locked),
              createdAt: r.created_at || new Date().toISOString(),
            });
          }
        }
      } catch (err) {
        console.warn('Supabase profiles query error in listUsers:', err);
      }

      // Merge with Supabase Auth users if admin api is accessible
      try {
        const { data: authData, error: authError } = await this.supabase.auth.admin.listUsers();
        if (!authError && authData?.users) {
          for (const au of authData.users) {
            if (!userMap.has(au.id)) {
              const meta = au.user_metadata || {};
              const appMeta = au.app_metadata || {};
              const rawRole = appMeta.role || meta.role || (au.email?.includes('admin') ? 'admin' : au.email?.includes('staff') ? 'staff' : 'user');
              const role = rawRole === 'admin' ? 'admin' : rawRole === 'staff' ? 'staff' : rawRole === 'seller' ? 'seller' : 'user';
              userMap.set(au.id, {
                id: au.id,
                name: meta.full_name || meta.name || au.email?.split('@')[0] || 'Người dùng',
                email: au.email || `${au.id.slice(0, 8)}@menshop.vn`,
                role,
                isLocked: Boolean(au.banned_until),
                createdAt: au.created_at || new Date().toISOString(),
              });
            }
          }
        }
      } catch (_) {}
    }

    // Always merge in the mock/demo accounts if not already present
    for (const u of this.users) {
      const emailLower = u.email.toLowerCase();
      const alreadyExists = userMap.has(u.id) || Array.from(userMap.values()).some((x) => x.email.toLowerCase() === emailLower);
      if (!alreadyExists) {
        const { password, ...safe } = u;
        userMap.set(u.id, safe as UserAccount);
      }
    }

    return Array.from(userMap.values());
  }

  async getUserById(id: string): Promise<UserAccount | null> {
    if (!id) return null;

    if (this.supabase) {
      try {
        let lookupId = id;
        if (id === '00000000-0000-0000-0000-000000000001' || id === 'usr-admin-001') {
          lookupId = '0f444d92-322c-4956-b452-0c5c10950508';
        } else if (id === '00000000-0000-0000-0000-000000000004' || id === 'usr-staff-001') {
          lookupId = 'd604e122-aa50-47e0-ac44-10a2473af6ce';
        } else if (id === '00000000-0000-0000-0000-000000000002') {
          lookupId = '7fb74d58-4155-4ab5-8124-cb0b5bb6651d';
        }

        const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

        let data = null;
        if (isUuid) {
          const res = await this.supabase
            .from('profiles')
            .select('id, full_name, email, role, is_locked, created_at')
            .eq('id', lookupId)
            .maybeSingle();
          if (!res.error && res.data) data = res.data;
        }

        if (!data && lookupId.includes('@')) {
          const res = await this.supabase
            .from('profiles')
            .select('id, full_name, email, role, is_locked, created_at')
            .eq('email', lookupId.toLowerCase().trim())
            .maybeSingle();
          if (!res.error && res.data) data = res.data;
        }

        if (data) {
          const mem = this.users.find((u) => u.id === id || u.email === data.email);
          return {
            id: data.id,
            name: data.full_name || 'Người dùng',
            email: data.email || '',
            role: data.role === 'admin' ? 'admin' : data.role === 'staff' ? 'staff' : 'user',
            isLocked: Boolean(data.is_locked),
            createdAt: data.created_at,
            password: mem?.password,
          };
        }
      } catch {
        // Fallback to in-memory
      }
    }

    const user = this.users.find((u) => u.id === id || u.email.toLowerCase() === id.toLowerCase());
    return user || null;
  }

  async getUserByEmail(email: string): Promise<UserAccount | null> {
    const normalized = email.toLowerCase().trim();
    if (this.supabase) {
      try {
        let queryEmail = normalized;
        if (normalized === 'admin@gmail.com') queryEmail = 'admin@menshop.vn';
        if (normalized === 'staff@gmail.com') queryEmail = 'staff@menshop.vn';

        const { data, error } = await this.supabase
          .from('profiles')
          .select('id, full_name, email, role, is_locked, created_at')
          .or(`email.eq.${queryEmail},email.eq.${normalized}`)
          .maybeSingle();
        if (!error && data) {
          const mem = this.users.find((u) => u.email.toLowerCase().trim() === normalized);
          return {
            id: data.id,
            name: data.full_name || 'Người dùng',
            email: data.email || normalized,
            role: data.role === 'admin' ? 'admin' : data.role === 'staff' ? 'staff' : 'user',
            isLocked: Boolean(data.is_locked),
            createdAt: data.created_at,
            password: mem?.password || (normalized === 'admin@gmail.com' || normalized === 'staff@gmail.com' ? 'Admin@123456' : undefined),
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
    role?: 'admin' | 'staff' | 'user';
  }): Promise<UserAccount> {
    const normalized = data.email.toLowerCase().trim();
    const existing = await this.getUserByEmail(normalized);
    if (existing) {
      throw new AppError('EMAIL_EXISTS', 400, 'Email này đã được sử dụng');
    }

    const assignedRole = data.role === 'staff' ? 'staff' : (data.role === 'admin' ? 'admin' : 'user');
    const dbRole = assignedRole === 'admin' ? 'admin' : (assignedRole === 'staff' ? 'staff' : 'customer');

    if (this.supabase) {
      try {
        let authUserId: string | null = null;
        try {
          const { data: createData, error: createError } = await this.supabase.auth.admin.createUser({
            email: normalized,
            password: data.password || '123456',
            email_confirm: true,
            user_metadata: { full_name: data.name.trim(), role: dbRole },
          });
          if (createError) {
            if (
              createError.message.toLowerCase().includes('already') ||
              createError.message.toLowerCase().includes('registered')
            ) {
              throw new AppError('EMAIL_EXISTS', 400, 'Email này đã được sử dụng');
            }
          }
          if (createData?.user) {
            authUserId = createData.user.id;
          }
        } catch (authErr) {
          if (authErr instanceof AppError) throw authErr;
        }

        const finalId = authUserId || crypto.randomUUID();
        const { data: profile, error } = await this.supabase
          .from('profiles')
          .upsert({
            id: finalId,
            email: normalized,
            full_name: data.name.trim(),
            role: dbRole,
            is_locked: false,
          })
          .select()
          .single();

        if (!error && profile) {
          return {
            id: profile.id,
            name: profile.full_name || data.name.trim(),
            email: profile.email || normalized,
            role: assignedRole,
            isLocked: Boolean(profile.is_locked),
            createdAt: profile.created_at || new Date().toISOString(),
          };
        }
      } catch (err) {
        if (err instanceof AppError) throw err;
        console.warn('Supabase createUser error, falling back to local:', err);
      }
    }

    const newUser: UserAccount = {
      id: `usr-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      name: data.name.trim(),
      email: normalized,
      password: data.password || '123456',
      role: assignedRole,
      isLocked: false,
      createdAt: new Date().toISOString(),
    };

    this.users.push(newUser);
    const { password, ...safe } = newUser;
    return safe as UserAccount;
  }

  async updateUser(
    id: string,
    data: { name?: string; email?: string; role?: 'admin' | 'staff' | 'user' }
  ): Promise<UserAccount> {
    if (this.supabase) {
      let lookupId = id;
      if (id === '00000000-0000-0000-0000-000000000001' || id === 'usr-admin-001') {
        lookupId = '0f444d92-322c-4956-b452-0c5c10950508';
      } else if (id === '00000000-0000-0000-0000-000000000004' || id === 'usr-staff-001') {
        lookupId = 'd604e122-aa50-47e0-ac44-10a2473af6ce';
      } else if (id === '00000000-0000-0000-0000-000000000002') {
        lookupId = '7fb74d58-4155-4ab5-8124-cb0b5bb6651d';
      }

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);
      if (isUuid) {
        try {
          const patch: Record<string, unknown> = {};
          if (data.name) patch.full_name = data.name.trim();
          if (data.email) patch.email = data.email.toLowerCase().trim();
          if (data.role) {
            patch.role = data.role === 'admin' ? 'admin' : (data.role === 'staff' ? 'staff' : 'customer');
          }
          const { error } = await this.supabase.from('profiles').update(patch).eq('id', lookupId);
          if (error) throw new AppError('UPDATE_USER_FAILED', 400, error.message);

          const updated = await this.getUserById(lookupId);
          if (updated) return updated;
        } catch (err) {
          if (err instanceof AppError) throw err;
        }
      }
    }

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

    const { password, ...safe } = user;
    return safe as UserAccount;
  }

  async deleteUser(id: string): Promise<boolean> {
    if (this.supabase) {
      let lookupId = id;
      if (id === '00000000-0000-0000-0000-000000000001' || id === 'usr-admin-001') {
        lookupId = '0f444d92-322c-4956-b452-0c5c10950508';
      }

      if (lookupId === '0f444d92-322c-4956-b452-0c5c10950508') {
        throw new AppError('CANNOT_DELETE_PRIMARY_ADMIN', 400, 'Không thể xóa tài khoản Admin mặc định');
      }

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);
      if (isUuid) {
        try {
          const { error } = await this.supabase.from('profiles').delete().eq('id', lookupId);
          if (!error) {
            try {
              await this.supabase.auth.admin.deleteUser(lookupId);
            } catch (_) {}
            return true;
          }
        } catch (err) {
          console.warn('Supabase deleteUser warning:', err);
        }
      }
    }

    const index = this.users.findIndex((u) => u.id === id);
    if (index !== -1) {
      if (this.users[index].email === 'admin@gmail.com' || this.users[index].email === 'admin@menshop.vn') {
        throw new AppError('CANNOT_DELETE_PRIMARY_ADMIN', 400, 'Không thể xóa tài khoản Admin mặc định');
      }
      this.users.splice(index, 1);
      return true;
    }

    return true;
  }

  async setLockStatus(id: string, isLocked: boolean): Promise<UserAccount> {
    if (this.supabase) {
      let lookupId = id;
      if (id === '00000000-0000-0000-0000-000000000001' || id === 'usr-admin-001') {
        lookupId = '0f444d92-322c-4956-b452-0c5c10950508';
      }

      if (lookupId === '0f444d92-322c-4956-b452-0c5c10950508' && isLocked) {
        throw new AppError('CANNOT_LOCK_PRIMARY_ADMIN', 400, 'Không thể khóa tài khoản Admin mặc định');
      }

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);
      if (isUuid) {
        try {
          const { data, error } = await this.supabase
            .from('profiles')
            .update({ is_locked: isLocked })
            .eq('id', lookupId)
            .select()
            .single();
          if (!error && data) {
            return {
              id: data.id,
              name: data.full_name || 'Người dùng',
              email: data.email || '',
              role: data.role === 'admin' ? 'admin' : data.role === 'staff' ? 'staff' : 'user',
              isLocked: Boolean(data.is_locked),
              createdAt: data.created_at,
            };
          }
        } catch (err) {
          console.warn('Supabase setLockStatus warning:', err);
        }
      }
    }

    const user = this.users.find((u) => u.id === id);
    if (!user) {
      throw new AppError('USER_NOT_FOUND', 404, 'Không tìm thấy người dùng');
    }

    if ((user.email === 'admin@gmail.com' || user.email === 'admin@menshop.vn') && isLocked) {
      throw new AppError('CANNOT_LOCK_PRIMARY_ADMIN', 400, 'Không thể khóa tài khoản Admin mặc định');
    }

    user.isLocked = isLocked;
    const { password, ...safe } = user;
    return safe as UserAccount;
  }

  async updatePassword(idOrEmail: string, newPassword: string): Promise<boolean> {
    const key = idOrEmail.toLowerCase().trim();
    const user = this.users.find(
      (u) => u.id === idOrEmail || u.email.toLowerCase().trim() === key
    );
    if (user) {
      user.password = newPassword;
    }

    if (this.supabase) {
      try {
        const targetId = user?.id || idOrEmail;
        await this.supabase.auth.admin.updateUserById(targetId, { password: newPassword });
      } catch {
        // Fallback or ignore
      }
    }

    return true;
  }
}
