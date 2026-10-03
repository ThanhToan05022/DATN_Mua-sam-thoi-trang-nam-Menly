'use client';

import React from 'react';
import { usePathname } from 'next/navigation';
import { Sidebar } from './Sidebar';
import { AdminAuthGuard } from './AdminAuthGuard';

export function AdminLayoutShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  if (pathname === '/login') {
    return <AdminAuthGuard>{children}</AdminAuthGuard>;
  }

  return (
    <AdminAuthGuard>
      <div className="flex min-h-screen w-full">
        <Sidebar />
        <div className="flex-1 flex flex-col min-w-0 min-h-screen overflow-x-hidden">
          {children}
        </div>
      </div>
    </AdminAuthGuard>
  );
}
