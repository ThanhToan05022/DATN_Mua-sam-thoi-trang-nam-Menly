'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Shirt,
  ShoppingBag,
  Boxes,
  Users,
  LogOut,
} from 'lucide-react';

const NAV_ITEMS = [
  { href: '/',          label: 'Tổng quan',          icon: LayoutDashboard },
  { href: '/products',  label: 'Sản phẩm',           icon: Shirt },
  { href: '/orders',    label: 'Đơn hàng',           icon: ShoppingBag },
  { href: '/inventory', label: 'Kho hàng & Tồn',    icon: Boxes },
  { href: '/users',     label: 'Người dùng',         icon: Users },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside style={{
      width: 232,
      background: 'var(--sidebar)',
      borderRight: '1px solid var(--border)',
      display: 'flex',
      flexDirection: 'column',
      height: '100vh',
      position: 'sticky',
      top: 0,
      flexShrink: 0,
      overflow: 'hidden',
    }}>
      {/* Brand glow */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 200,
        background: 'radial-gradient(ellipse at 50% -20%, rgba(244,81,30,0.18), transparent 70%)',
        pointerEvents: 'none',
      }} />

      {/* Logo */}
      <div style={{
        padding: '22px 20px 18px',
        borderBottom: '1px solid var(--border)',
        position: 'relative',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 12,
            background: 'linear-gradient(135deg, var(--brand), var(--brand-2))',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 900, fontSize: 18, color: '#fff',
            boxShadow: '0 4px 14px var(--brand-shadow)',
          }}>M</div>
          <div>
            <div style={{ fontWeight: 800, fontSize: 15, color: 'var(--text)', letterSpacing: '0.08em' }}>
              MENLY
            </div>
            <div style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.1em' }}>
              Admin Portal
            </div>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav style={{ flex: 1, padding: '14px 10px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 3 }}>
        {NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));
          return (
            <Link key={item.href} href={item.href} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '10px 12px', borderRadius: 14,
              fontWeight: 600, fontSize: 13,
              color: isActive ? '#fff' : 'var(--text-2)',
              background: isActive
                ? 'linear-gradient(90deg, rgba(244,81,30,0.25), rgba(244,81,30,0.08))'
                : 'transparent',
              borderLeft: isActive ? '3px solid var(--brand)' : '3px solid transparent',
              textDecoration: 'none',
              transition: 'all 0.15s',
            }}>
              <Icon size={16} color={isActive ? 'var(--brand)' : 'var(--text-muted)'} />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div style={{ padding: '14px 10px', borderTop: '1px solid var(--border)' }}>
        <button style={{
          display: 'flex', alignItems: 'center', gap: 10,
          width: '100%', padding: '10px 12px', borderRadius: 14,
          background: 'transparent', border: 'none', cursor: 'pointer',
          color: 'var(--text-muted)', fontSize: 13, fontWeight: 600,
          fontFamily: 'inherit', transition: 'all 0.15s',
        }}
          onMouseEnter={e => (e.currentTarget.style.background = 'var(--fill-1)')}
          onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
        >
          <LogOut size={16} />
          <span>Đăng xuất</span>
        </button>
      </div>
    </aside>
  );
}
