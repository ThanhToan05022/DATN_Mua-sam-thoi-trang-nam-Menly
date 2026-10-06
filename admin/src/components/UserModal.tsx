'use client';

import React, { useState } from 'react';
import { Modal } from './Modal';
import { UserAccount } from '../lib/types';

interface AddUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: {
    name: string;
    email: string;
    password?: string;
    role: 'admin' | 'staff' | 'user' | 'seller';
  }) => Promise<void>;
}

export function AddUserModal({ isOpen, onClose, onSubmit }: AddUserModalProps) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('123456');
  const [role, setRole] = useState<'admin' | 'staff' | 'user' | 'seller'>('user');
  const [submitting, setSubmitting] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setErr(null);
    try {
      await onSubmit({ name, email, password, role });
      setName('');
      setEmail('');
      setPassword('123456');
      onClose();
    } catch (e: unknown) {
      setErr((e as Error).message || 'Lỗi khi tạo người dùng');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Thêm Người Dùng Mới">
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        {err && (
          <div className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400">
            {err}
          </div>
        )}
        <div>
          <label className="block text-slate-300 font-semibold mb-1">Họ và tên</label>
          <input
            type="text"
            required
            placeholder="VD: Tran Van Nam"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs"
          />
        </div>
        <div>
          <label className="block text-slate-300 font-semibold mb-1">Địa chỉ Email</label>
          <input
            type="email"
            required
            placeholder="nam@gmail.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs"
          />
        </div>
        <div>
          <label className="block text-slate-300 font-semibold mb-1">Mật khẩu ban đầu</label>
          <input
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs"
          />
        </div>
        <div>
          <label className="block text-slate-300 font-semibold mb-1">Vai trò</label>
          <select
            value={role}
            onChange={(e) => setRole(e.target.value as 'admin' | 'staff' | 'user' | 'seller')}
            className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs"
          >
            <option value="user">Khách hàng (User)</option>
            <option value="staff">Nhân viên (Staff)</option>
            <option value="seller">Người bán (Seller)</option>
            <option value="admin">Quản trị viên (Admin)</option>
          </select>
        </div>
        <div className="flex justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-slate-400 hover:text-white"
          >
            Hủy
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="px-4 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold hover:bg-amber-400 transition-colors disabled:opacity-50"
          >
            {submitting ? 'Đang tạo...' : 'Tạo tài khoản'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

interface EditUserModalProps {
  user: UserAccount | null;
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (id: string, data: { name?: string; email?: string; role?: 'admin' | 'staff' | 'user' | 'seller' }) => Promise<void>;
}

export function EditUserModal({ user, isOpen, onClose, onSubmit }: EditUserModalProps) {
  const [name, setName] = useState(user?.name || user?.fullName || '');
  const [email, setEmail] = useState(user?.email || '');
  const [role, setRole] = useState<'admin' | 'staff' | 'user' | 'seller'>('user');
  const [submitting, setSubmitting] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  React.useEffect(() => {
    if (user) {
      setName(user.name || user.fullName || '');
      setEmail(user.email);
      setRole((user.role as any) || 'user');
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setSubmitting(true);
    setErr(null);
    try {
      await onSubmit(user.id, { name, email, role });
      onClose();
    } catch (e: unknown) {
      setErr((e as Error).message || 'Lỗi khi cập nhật');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Chỉnh Sửa Thông Tin Người Dùng">
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        {err && (
          <div className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400">
            {err}
          </div>
        )}
        <div>
          <label className="block text-slate-300 font-semibold mb-1">Họ và tên</label>
          <input
            type="text"
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs"
          />
        </div>
        <div>
          <label className="block text-slate-300 font-semibold mb-1">Địa chỉ Email</label>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs"
          />
        </div>
        <div>
          <label className="block text-slate-300 font-semibold mb-1">Vai trò</label>
          <select
            value={role}
            disabled={user?.email === 'admin@gmail.com'}
            onChange={(e) => setRole(e.target.value as 'admin' | 'staff' | 'user' | 'seller')}
            className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-white text-xs disabled:opacity-50"
          >
            <option value="user">Khách hàng (User)</option>
            <option value="staff">Nhân viên (Staff)</option>
            <option value="seller">Người bán (Seller)</option>
            <option value="admin">Quản trị viên (Admin)</option>
          </select>
        </div>
        <div className="flex justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-slate-400 hover:text-white"
          >
            Hủy
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="px-4 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold hover:bg-amber-400 transition-colors disabled:opacity-50"
          >
            {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
