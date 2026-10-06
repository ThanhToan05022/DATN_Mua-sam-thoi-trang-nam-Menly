'use client';

import React, { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';

export function AdminAuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    if (pathname === '/login') {
      setAuthorized(true);
      return;
    }

    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('menshop_admin_token');
      const userStr = localStorage.getItem('menshop_admin_user');

      if (!token) {
        // If not logged in, redirect to login
        router.replace('/login');
        return;
      }

      if (userStr) {
        try {
          const user = JSON.parse(userStr);
          if (user.role && user.role !== 'admin') {
            router.replace('/login');
            return;
          }
        } catch {
          // ignore parse error
        }
      }

      setAuthorized(true);
    }
  }, [pathname, router]);

  if (!authorized && pathname !== '/login') {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center text-slate-400 text-sm">
        Đang kiểm tra quyền đăng nhập quản trị...
      </div>
    );
  }

  return <>{children}</>;
}
