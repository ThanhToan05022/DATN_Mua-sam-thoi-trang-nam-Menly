-- ==============================================================================
-- BẢNG: WISHLISTS (DANH SÁCH YÊU THÍCH SẢN PHẨM)
-- Lưu trữ sản phẩm người dùng đánh dấu quan tâm / yêu thích để mua sau
-- ==============================================================================

create table if not exists public.wishlists (
  user_id uuid not null references auth.users on delete cascade,
  product_id uuid not null references public.products on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);
