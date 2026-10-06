'use client';

import React from 'react';
import { UserAccount } from '../lib/types';
import { Shield, User as UserIcon, Lock, Unlock, Edit2, Trash2 } from 'lucide-react';

interface UsersTableProps {
  users: UserAccount[];
  loading: boolean;
  onToggleLock: (u: UserAccount) => void;
  onEdit: (u: UserAccount) => void;
  onDelete: (u: UserAccount) => void;
}

export function UsersTable({
  users,
  loading,
  onToggleLock,
  onEdit,
  onDelete,
}: UsersTableProps) {
  return (
    <div className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
      {loading ? (
        <div className="py-20 text-center text-slate-500 text-sm">Đang tải danh sách người dùng...</div>
      ) : users.length === 0 ? (
        <div className="py-20 text-center text-slate-500 text-sm">Không tìm thấy người dùng nào</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-800 text-xs text-slate-400 uppercase tracking-wider font-semibold bg-slate-950/40">
                <th className="py-3 px-4">Tài khoản & Email</th>
                <th className="py-3 px-4">Vai trò</th>
                <th className="py-3 px-4">Trạng thái đăng nhập</th>
                <th className="py-3 px-4">Ngày tạo</th>
                <th className="py-3 px-4 text-right">Thao tác quản trị</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 text-slate-300 text-xs">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-slate-800/40 transition-colors">
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs ${
                          u.role === 'admin'
                            ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                            : 'bg-slate-800 text-slate-300'
                        }`}
                      >
                        {u.name ? u.name.charAt(0).toUpperCase() : 'U'}
                      </div>
                      <div>
                        <p className="font-semibold text-white">{u.name}</p>
                        <p className="text-slate-400 font-mono text-[11px]">{u.email}</p>
                      </div>
                    </div>
                  </td>

                  <td className="py-3 px-4">
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full font-bold text-[10px] border ${
                        u.role === 'admin'
                          ? 'bg-amber-500/15 text-amber-400 border-amber-500/30'
                          : u.role === 'staff'
                          ? 'bg-purple-500/15 text-purple-400 border-purple-500/30'
                          : u.role === 'seller'
                          ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30'
                          : 'bg-blue-500/15 text-blue-400 border-blue-500/30'
                      }`}
                    >
                      {u.role === 'admin' ? <Shield className="w-3 h-3" /> : <UserIcon className="w-3 h-3" />}
                      {u.role === 'admin'
                        ? 'Quản trị viên (Admin)'
                        : u.role === 'staff'
                        ? 'Nhân viên (Staff)'
                        : u.role === 'seller'
                        ? 'Người bán (Seller)'
                        : 'Khách hàng (User)'}
                    </span>
                  </td>

                  <td className="py-3 px-4">
                    <span
                      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-bold text-[10px] border ${
                        u.isLocked
                          ? 'bg-rose-500/15 text-rose-400 border-rose-500/30'
                          : 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30'
                      }`}
                    >
                      <span
                        className={`w-1.5 h-1.5 rounded-full ${
                          u.isLocked ? 'bg-rose-400' : 'bg-emerald-400'
                        }`}
                      />
                      {u.isLocked ? 'Đã bị khóa đăng nhập' : 'Đang hoạt động'}
                    </span>
                  </td>

                  <td className="py-3 px-4 font-mono text-slate-400">
                    {new Date(u.createdAt).toLocaleDateString('vi-VN')}
                  </td>

                  <td className="py-3 px-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => onToggleLock(u)}
                        disabled={u.email === 'admin@gmail.com'}
                        className={`p-1.5 rounded-lg border text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed ${
                          u.isLocked
                            ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/25'
                            : 'bg-rose-500/15 text-rose-400 border-rose-500/30 hover:bg-rose-500/25'
                        }`}
                        title={u.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'}
                      >
                        {u.isLocked ? <Unlock className="w-3.5 h-3.5" /> : <Lock className="w-3.5 h-3.5" />}
                        {u.isLocked ? 'Mở khóa' : 'Khóa TK'}
                      </button>

                      <button
                        onClick={() => onEdit(u)}
                        className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700 transition-colors cursor-pointer"
                        title="Chỉnh sửa thông tin"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>

                      <button
                        onClick={() => onDelete(u)}
                        disabled={u.email === 'admin@gmail.com'}
                        className="p-1.5 rounded-lg bg-slate-800 hover:bg-rose-900/40 text-slate-400 hover:text-rose-400 border border-slate-700 transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
                        title="Xóa tài khoản"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
