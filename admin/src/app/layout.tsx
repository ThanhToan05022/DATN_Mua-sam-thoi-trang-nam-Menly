import type { Metadata } from 'next';
import './globals.css';
import { AdminLayoutShell } from '../components/AdminLayoutShell';

export const metadata: Metadata = {
  title: 'Menly Admin Portal | Bảng điều khiển quản trị',
  description: 'Quản trị hệ thống thời trang nam Menly - Danh mục, Sản phẩm, Đơn hàng & Tồn kho',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="vi">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet" />
      </head>
      <body style={{ background: 'var(--bg)', color: 'var(--text)', minHeight: '100vh' }}>
        <AdminLayoutShell>{children}</AdminLayoutShell>
      </body>
    </html>
  );
}
