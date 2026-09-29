-- ==============================================================================
-- BẢNG: VOUCHERS (MÃ GIẢM GIÁ TOÀN SÀN & SHOP)
-- Hỗ trợ voucher toàn sàn (shop_id = NULL) hoặc voucher riêng của từng Shop
-- ==============================================================================

create table if not exists public.vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  shop_id uuid references public.shops on delete cascade,
  title text not null,
  discount_type text not null check (discount_type in ('percentage', 'fixed_amount')),
  discount_value int not null check (discount_value > 0),
  min_order_value int not null default 0,
  max_discount int,
  usage_limit int not null default 100,
  used_count int not null default 0,
  start_date timestamptz not null default now(),
  end_date timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
