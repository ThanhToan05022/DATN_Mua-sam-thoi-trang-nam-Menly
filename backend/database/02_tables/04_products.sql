-- ==============================================================================
-- BẢNG: PRODUCTS (SẢN PHẨM THỜI TRANG NAM)
-- Lưu trữ sản phẩm chính, danh mục, giá niêm yết, chuỗi tìm kiếm không dấu,
-- liên kết gian hàng (shop_id), kiểm duyệt (approval_status) và rating trung bình.
-- ==============================================================================

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories,
  shop_id uuid references public.shops on delete cascade,
  name text not null,
  slug text not null unique,
  description text,
  price int not null check (price >= 0),
  thumbnail_url text,
  search_text text not null default '',
  approval_status text not null default 'approved' check (approval_status in ('pending', 'approved', 'rejected')),
  rating_avg numeric(3,2) not null default 0.00,
  rating_count int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Bổ sung các cột nếu bảng đã tồn tại từ phiên bản trước
alter table public.products add column if not exists shop_id uuid references public.shops on delete cascade;
alter table public.products add column if not exists approval_status text not null default 'approved' check (approval_status in ('pending', 'approved', 'rejected'));
alter table public.products add column if not exists rating_avg numeric(3,2) not null default 0.00;
alter table public.products add column if not exists rating_count int not null default 0;
