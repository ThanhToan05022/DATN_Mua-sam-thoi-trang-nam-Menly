'use client';

import { useState, useEffect } from 'react';
import { Header } from '@/components/Header';
import { checkServerHealth } from '@/lib/api';
import { Settings, Server, Database, RefreshCw, CheckCircle2 } from 'lucide-react';

export default function SettingsPage() {
  const [apiUrl, setApiUrl] = useState('http://localhost:5000');
  const [adminToken, setAdminToken] = useState('Bearer mock-admin-123');
  const [isOnline, setIsOnline] = useState<boolean | null>(null);
  const [checking, setChecking] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const storedUrl = localStorage.getItem('menshop_api_url') || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';
      const storedToken = localStorage.getItem('menshop_admin_token') || process.env.NEXT_PUBLIC_ADMIN_TOKEN || 'Bearer mock-admin-123';
      setApiUrl(storedUrl);
      setAdminToken(storedToken);
    }
    verify();
  }, []);

  async function verify() {
    setChecking(true);
    const ok = await checkServerHealth();
    setIsOnline(ok);
    setChecking(false);
  }

  function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (typeof window !== 'undefined') {
      localStorage.setItem('menshop_api_url', apiUrl);
      localStorage.setItem('menshop_admin_token', adminToken);
    }
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
    verify();
  }

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Cấu hình Hệ thống & Kết nối API"
        subtitle="Quản lý địa chỉ máy chủ Backend, Token xác thực quản trị và trạng thái CSDL"
        onRefresh={verify}
      />

      <div className="p-8 space-y-8 flex-1 max-w-4xl">
        {/* Saved Alert */}
        {saved && (
          <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4" />
            <span>Đã lưu cấu hình kết nối API vào LocalStorage của trình duyệt thành công!</span>
          </div>
        )}

        {/* Server Status Card */}
        <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <Server className="w-5 h-5 text-amber-400" />
              <h3 className="font-bold text-base text-white">Trạng thái Kết nối Backend Node.js</h3>
            </div>
            <button
              onClick={verify}
              disabled={checking}
              className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${checking ? 'animate-spin' : ''}`} />
              Kiểm tra ngay
            </button>
          </div>

          <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-slate-300">Endpoint Kiểm thử: {apiUrl}/health</p>
              <p className="text-[11px] text-slate-500 mt-0.5">Kiểm tra liveness qua HTTP GET</p>
            </div>
            <span
              className={`px-3 py-1 rounded-full text-xs font-bold border ${
                isOnline
                  ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30'
                  : 'bg-amber-500/10 text-amber-400 border-amber-500/30'
              }`}
            >
              {isOnline ? 'Online (HTTP 200 OK)' : 'Offline / Standby'}
            </span>
          </div>
        </div>

        {/* Form Config */}
        <form onSubmit={handleSave} className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6 space-y-5">
          <div className="flex items-center gap-2 mb-2">
            <Settings className="w-5 h-5 text-amber-400" />
            <h3 className="font-bold text-base text-white">Tham số Kết nối API</h3>
          </div>

          <div className="space-y-4 text-xs">
            <div>
              <label className="text-slate-300 font-semibold block mb-1">
                Địa chỉ Backend API URL (Mặc định: http://localhost:5000)
              </label>
              <input
                type="text"
                value={apiUrl}
                onChange={(e) => setApiUrl(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-amber-500"
              />
            </div>

            <div>
              <label className="text-slate-300 font-semibold block mb-1">
                Admin Authorization Token (Bearer Token)
              </label>
              <input
                type="text"
                value={adminToken}
                onChange={(e) => setAdminToken(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-amber-500"
              />
              <p className="text-[11px] text-slate-500 mt-1">
                Sử dụng token &quot;Bearer mock-admin-123&quot; cho môi trường dev/test hoặc token Supabase Auth JWT hợp lệ của tài khoản admin.
              </p>
            </div>
          </div>

          <div className="pt-2 flex justify-end">
            <button
              type="submit"
              className="px-6 py-2.5 rounded-xl font-bold bg-amber-500 text-slate-950 hover:bg-amber-400 transition-colors text-xs cursor-pointer shadow-md"
            >
              Lưu cấu hình
            </button>
          </div>
        </form>

        {/* Architecture Specs */}
        <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6 space-y-4 text-xs">
          <div className="flex items-center gap-2">
            <Database className="w-5 h-5 text-amber-400" />
            <h3 className="font-bold text-base text-white">Kiến trúc Hệ thống MenShop</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-1">
            <div className="p-3.5 rounded-xl bg-slate-950/80 border border-slate-800 space-y-1">
              <span className="font-semibold text-amber-400">Backend MVVM:</span>
              <p className="text-slate-300">Node.js 22+, Express, TypeScript, Zod, Pino Logging, Vitest (15/15 tests pass).</p>
            </div>
            <div className="p-3.5 rounded-xl bg-slate-950/80 border border-slate-800 space-y-1">
              <span className="font-semibold text-amber-400">Database & Storage:</span>
              <p className="text-slate-300">Supabase PostgreSQL 15, Row Level Security (RLS), ACID audit logs, 125 sản phẩm thực tế.</p>
            </div>
            <div className="p-3.5 rounded-xl bg-slate-950/80 border border-slate-800 space-y-1">
              <span className="font-semibold text-amber-400">Cổng Thanh toán:</span>
              <p className="text-slate-300">VNPay Sandbox tích hợp mã hóa HMAC-SHA512 + COD (Thanh toán khi nhận hàng).</p>
            </div>
            <div className="p-3.5 rounded-xl bg-slate-950/80 border border-slate-800 space-y-1">
              <span className="font-semibold text-amber-400">Giao diện Admin Web:</span>
              <p className="text-slate-300">Next.js 16 (App Router), React 19, TypeScript, Lucide Icons, Dark Luxury Theme.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
