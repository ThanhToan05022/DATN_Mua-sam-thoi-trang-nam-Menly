-- ==============================================================================
-- BẢNG: ORDERS (ĐƠN HÀNG)
-- Quản lý toàn bộ vòng đời đơn hàng: mã đơn, người mua, gian hàng (shop_id),
-- phương thức thanh toán (COD / VNPay), trạng thái, thông tin giao hàng, idempotency key
-- ==============================================================================

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  user_id uuid not null references auth.users,
  shop_id uuid references public.shops,
  parent_order_id uuid references public.orders(id) on delete cascade,
  status order_status not null default 'pending_payment',
  payment_method text not null check (payment_method in ('cod', 'vnpay')),
  subtotal int not null,
  shipping_fee int not null default 0,
  total int not null,
  ship_name text not null,
  ship_phone text not null,
  ship_address text not null,
  idempotency_key text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

-- Bổ sung cột shop_id và parent_order_id nếu bảng đã tồn tại
alter table public.orders add column if not exists shop_id uuid references public.shops;
alter table public.orders add column if not exists parent_order_id uuid references public.orders(id) on delete cascade;
