'use client';

import { useRouter } from 'next/navigation';
import { RefreshCw, LogOut } from 'lucide-react';

interface HeaderProps {
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
}

export function Header({ title, subtitle, onRefresh }: HeaderProps) {
  const router = useRouter();

  function handleLogout() {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('menshop_admin_token');
      localStorage.removeItem('menshop_admin_user');
      router.push('/login');
    }
  }

  return (
    <header className="bg-slate-900/60 backdrop-blur-md border-b border-slate-800 px-8 py-4.5 flex items-center justify-between sticky top-0 z-20">
      <div>
        <h1 className="text-xl font-bold text-white tracking-tight">{title}</h1>
        {subtitle && <p className="text-xs text-slate-400 mt-0.5">{subtitle}</p>}
      </div>

      <div className="flex items-center gap-4">
        {/* Refresh Button */}
        {onRefresh && (
          <button
            onClick={onRefresh}
            className="p-2 rounded-lg bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-white transition-all cursor-pointer"
            title="Làm mới dữ liệu"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        )}

        {/* Logout Button */}
        <button
          onClick={handleLogout}
          className="p-2 px-3 rounded-lg bg-slate-800/80 hover:bg-rose-950/40 text-slate-400 hover:text-rose-400 border border-slate-800 hover:border-rose-800/40 transition-all cursor-pointer flex items-center gap-1.5 text-xs font-semibold"
          title="Đăng xuất khỏi hệ thống"
        >
          <LogOut className="w-3.5 h-3.5" />
          <span className="hidden sm:inline">Đăng xuất</span>
        </button>
      </div>
    </header>
  );
}
