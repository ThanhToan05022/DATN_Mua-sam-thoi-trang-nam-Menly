-- ==============================================================================
-- BẢNG: CART_ITEMS (GIỎ HÀNG NGƯỜI DÙNG)
-- Lưu trữ các mặt hàng người dùng thêm vào giỏ trước khi tạo đơn hàng
-- ==============================================================================

create table if not exists public.cart_items (
  user_id uuid not null references auth.users on delete cascade,
  variant_id uuid not null references public.product_variants on delete cascade,
  quantity int not null check (quantity between 1 and 20),
  updated_at timestamptz not null default now(),
  primary key (user_id, variant_id)
);
