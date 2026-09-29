-- ==============================================================================
-- BẢNG: PRODUCT_REVIEWS (ĐÁNH GIÁ & NHẬN XÉT SẢN PHẨM)
-- Cho phép khách hàng đã mua sản phẩm đánh giá số sao (1-5), gửi nhận xét, ảnh và shop phản hồi
-- ==============================================================================

create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products on delete cascade,
  order_item_id uuid not null references public.order_items,
  user_id uuid not null references auth.users,
  rating int not null check (rating between 1 and 5),
  comment text,
  images jsonb default '[]'::jsonb,
  reply_comment text,
  reply_at timestamptz,
  created_at timestamptz not null default now(),
  unique (order_item_id)
);
