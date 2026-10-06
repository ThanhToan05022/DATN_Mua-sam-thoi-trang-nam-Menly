import type { Metadata } from 'next';
import './globals.css';
import { AdminLayoutShell } from '../components/AdminLayoutShell';

export const metadata: Metadata = {
  title: 'MenShop Admin Portal | Bảng điều khiển quản trị',
  description: 'Quản trị hệ thống thời trang nam MenShop - Danh mục, Sản phẩm, Đơn hàng & Tồn kho',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="vi" className="dark">
      <body className="bg-slate-950 text-slate-100 font-sans antialiased min-h-screen">
        <AdminLayoutShell>{children}</AdminLayoutShell>
      </body>
    </html>
  );
}
