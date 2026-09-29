-- ==============================================================================
-- BẢNG: SHOP_FOLLOWERS (THEO DÕI GIAN HÀNG)
-- Người dùng theo dõi shop để nhận thông báo hàng mới và voucher độc quyền
-- ==============================================================================

create table if not exists public.shop_followers (
  user_id uuid not null references auth.users on delete cascade,
  shop_id uuid not null references public.shops on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, shop_id)
);
