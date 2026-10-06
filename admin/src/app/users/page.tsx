'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import { UsersTable } from '../../components/UsersTable';
import { AddUserModal, EditUserModal } from '../../components/UserModal';
import {
  fetchAdminUsers,
  createAdminUser,
  updateAdminUser,
  deleteAdminUser,
  toggleLockAdminUser,
} from '../../lib/user-api';
import { UserAccount } from '../../lib/types';
import { UserPlus, Search, CheckCircle2, AlertCircle } from 'lucide-react';

export default function UsersPage() {
  const [users, setUsers] = useState<UserAccount[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'admin' | 'staff' | 'user' | 'seller'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'locked'>('all');

  const [isAddOpen, setIsAddOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<UserAccount | null>(null);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadUsers = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchAdminUsers();
      setUsers(data);
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Lỗi khi tải danh sách người dùng', type: 'error' });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const handleToggleLock = async (u: UserAccount) => {
    try {
      const nextLocked = !u.isLocked;
      await toggleLockAdminUser(u.id, nextLocked);
      setUsers((prev) =>
        prev.map((item) => (item.id === u.id ? { ...item, isLocked: nextLocked } : item))
      );
      setMsg({
        text: nextLocked
          ? `Đã khóa tài khoản ${u.email}. Tài khoản này không thể đăng nhập được nữa!`
          : `Đã mở khóa tài khoản ${u.email} thành công!`,
        type: 'success',
      });
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Lỗi khi cập nhật trạng thái', type: 'error' });
    }
  };

  const handleDelete = async (u: UserAccount) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa tài khoản ${u.email}?`)) return;
    try {
      await deleteAdminUser(u.id);
      setUsers((prev) => prev.filter((item) => item.id !== u.id));
      setMsg({ text: `Đã xóa tài khoản ${u.email} thành công!`, type: 'success' });
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Lỗi khi xóa người dùng', type: 'error' });
    }
  };

  const filteredUsers = users.filter((u) => {
    const nameMatch = (u.name || u.fullName || '').toLowerCase();
    const emailMatch = (u.email || '').toLowerCase();
    const query = search.toLowerCase().trim();
    const matchesSearch = !query || nameMatch.includes(query) || emailMatch.includes(query);

    const userRole = (u.role || '').toLowerCase();
    const matchesRole =
      roleFilter === 'all' ||
      userRole === roleFilter ||
      (roleFilter === 'user' && (userRole === 'user' || userRole === 'customer')) ||
      (roleFilter === 'staff' && userRole === 'staff') ||
      (roleFilter === 'admin' && userRole === 'admin') ||
      (roleFilter === 'seller' && userRole === 'seller');

    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && !u.isLocked) ||
      (statusFilter === 'locked' && Boolean(u.isLocked));
    return matchesSearch && matchesRole && matchesStatus;
  });

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Người dùng & Phân quyền"
        subtitle="Quản lý danh sách tài khoản, phân quyền Admin/User, thêm sửa xóa và khóa tài khoản"
        onRefresh={loadUsers}
      />

      <div className="p-8 space-y-6 flex-1">
        {msg && (
          <div
            className={`p-3.5 rounded-xl text-xs font-semibold flex items-center gap-2 ${
              msg.type === 'success'
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
            }`}
          >
            {msg.type === 'success' ? <CheckCircle2 className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
            <span>{msg.text}</span>
          </div>
        )}

        {/* Filters and Add button */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-slate-900/60 p-4 rounded-2xl border border-slate-800">
          <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            <div className="relative flex-1 sm:w-64">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="text"
                placeholder="Tìm tên hoặc email..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-amber-500"
              />
            </div>
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value as 'all' | 'admin' | 'staff' | 'user' | 'seller')}
              className="px-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-300"
            >
              <option value="all">Tất cả vai trò</option>
              <option value="admin">Quản trị viên (Admin)</option>
              <option value="staff">Nhân viên (Staff)</option>
              <option value="user">Khách hàng (User)</option>
              <option value="seller">Người bán (Seller)</option>
            </select>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as 'all' | 'active' | 'locked')}
              className="px-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-300"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="active">Đang hoạt động</option>
              <option value="locked">Đã bị khóa</option>
            </select>
          </div>

          <button
            onClick={() => setIsAddOpen(true)}
            className="w-full sm:w-auto px-4 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold text-xs hover:bg-amber-400 transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-md"
          >
            <UserPlus className="w-4 h-4" />
            Thêm người dùng mới
          </button>
        </div>

        {/* Users Table Component */}
        <UsersTable
          users={filteredUsers}
          loading={loading}
          onToggleLock={handleToggleLock}
          onEdit={(u) => setEditingUser(u)}
          onDelete={handleDelete}
        />
      </div>

      <AddUserModal
        isOpen={isAddOpen}
        onClose={() => setIsAddOpen(false)}
        onSubmit={async (data) => {
          const newUser = await createAdminUser(data);
          setUsers((prev) => [newUser, ...prev]);
          setMsg({ text: `Đã tạo tài khoản ${newUser.email} thành công!`, type: 'success' });
        }}
      />

      <EditUserModal
        user={editingUser}
        isOpen={Boolean(editingUser)}
        onClose={() => setEditingUser(null)}
        onSubmit={async (id, data) => {
          const updated = await updateAdminUser(id, data);
          setUsers((prev) => prev.map((item) => (item.id === id ? updated : item)));
          setMsg({ text: `Đã cập nhật tài khoản ${updated.email} thành công!`, type: 'success' });
        }}
      />
    </div>
  );
}
