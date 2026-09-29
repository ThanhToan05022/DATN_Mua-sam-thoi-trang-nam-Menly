'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { loginUser, getLockoutStatus } from '@/lib/api';
import { registerUser } from '@/lib/user-api';
import { ShieldCheck, UserPlus, LogIn, AlertCircle, CheckCircle2 } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [mode, setMode] = useState<'login' | 'register'>('login');

  // Form states
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const res = await loginUser(email, password);
      if (res.user.role !== 'admin') {
        throw new Error('Chỉ tài khoản Quản trị viên (Admin) mới có quyền truy cập trang quản trị!');
      }

      setSuccessMsg(`Đăng nhập thành công! Chào mừng ${res.user.fullName || res.user.email}`);
      localStorage.setItem('menshop_admin_token', `Bearer ${res.accessToken}`);
      localStorage.setItem('menshop_admin_user', JSON.stringify(res.user));

      setTimeout(() => {
        router.push('/');
      }, 800);
    } catch (err: unknown) {
      const error = err as { message?: string };
      setErrorMsg(
        error.message ||
          'Không kết nối được tới máy chủ. Hãy chắc chắn backend đang chạy tại http://localhost:5000'
      );
      try {
        await getLockoutStatus(email);
      } catch {
        // ignore
      }
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setErrorMsg('Vui lòng nhập họ và tên');
      return;
    }
    setLoading(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const res = await registerUser(name, email, password);
      setSuccessMsg(`Đăng ký thành công tài khoản người dùng ${res.user.email}! Đang chuyển sang đăng nhập...`);
      setTimeout(() => {
        setMode('login');
        setSuccessMsg('Đăng ký người dùng hoàn tất, vui lòng nhấn Đăng nhập để tiếp tục.');
      }, 1200);
    } catch (err: unknown) {
      const error = err as Error;
      setErrorMsg(error.message || 'Đăng ký tài khoản thất bại');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 p-4">
      <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-8 shadow-2xl">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-500/15 border border-amber-500/30 text-amber-400 font-bold text-2xl mb-3 shadow-lg">
            M
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">MenShop Admin Portal</h1>
          <p className="text-xs text-slate-400 mt-1">Cổng quản trị hệ thống thương mại điện tử</p>
        </div>

        {/* Tab switcher: Đăng nhập / Đăng ký */}
        <div className="flex bg-slate-950 p-1 rounded-xl border border-slate-800 text-xs mb-6">
          <button
            type="button"
            onClick={() => {
              setMode('login');
              setErrorMsg(null);
              setSuccessMsg(null);
            }}
            className={`flex-1 py-2 rounded-lg font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
              mode === 'login' ? 'bg-amber-500 text-slate-950 shadow-md' : 'text-slate-400 hover:text-white'
            }`}
          >
            <LogIn className="w-3.5 h-3.5" />
            Đăng nhập
          </button>
          <button
            type="button"
            onClick={() => {
              setMode('register');
              setErrorMsg(null);
              setSuccessMsg(null);
            }}
            className={`flex-1 py-2 rounded-lg font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
              mode === 'register' ? 'bg-amber-500 text-slate-950 shadow-md' : 'text-slate-400 hover:text-white'
            }`}
          >
            <UserPlus className="w-3.5 h-3.5" />
            Đăng ký
          </button>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="mb-4 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        <form onSubmit={mode === 'login' ? handleLogin : handleRegister} className="space-y-4">
          {mode === 'register' && (
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1">Họ và tên</label>
              <input
                type="text"
                placeholder="VD: Nguyen Van A"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                required
              />
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Địa chỉ Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Mật khẩu</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
              required
            />
          </div>

          {mode === 'register' && (
            <div className="p-3 rounded-xl bg-slate-950/80 border border-slate-800 text-[11px] text-slate-400">
              <span className="text-amber-400 font-semibold block mb-0.5">Phân quyền tài khoản:</span>
              Tài khoản đăng ký mới là <span className="text-white font-semibold">Người dùng (Khách hàng)</span>.
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 rounded-xl bg-amber-500 text-slate-950 font-bold hover:bg-amber-400 transition-all cursor-pointer disabled:opacity-50 text-sm shadow-md mt-2 flex items-center justify-center gap-2"
          >
            {loading ? (
              'Đang xử lý...'
            ) : mode === 'login' ? (
              <>
                <ShieldCheck className="w-4 h-4" />
                Đăng nhập Admin
              </>
            ) : (
              <>
                <UserPlus className="w-4 h-4" />
                Đăng ký Người dùng
              </>
            )}
          </button>
        </form>

        {mode === 'login' && (
          <div className="mt-6 p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 text-[11px] text-slate-400">
            <span className="text-amber-400 font-semibold block mb-0.5">Tài khoản quản trị mặc định:</span>
            Email: <code className="text-slate-200 font-mono font-bold">admin@gmail.com</code> • Mật khẩu:{' '}
            <code className="text-slate-200 font-mono font-bold">123456</code>
          </div>
        )}
      </div>
    </div>
  );
}
