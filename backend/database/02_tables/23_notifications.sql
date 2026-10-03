-- ==============================================================================
-- BẢNG: NOTIFICATIONS (THÔNG BÁO ĐẨY / HỆ THỐNG)
-- Thông báo tiến trình đơn hàng (order), khuyến mãi (promo) và hệ thống (system)
-- ==============================================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('order', 'promo', 'system')),
  data jsonb default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
