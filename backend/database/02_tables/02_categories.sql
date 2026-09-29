-- ==============================================================================
-- BẢNG: CATEGORIES (DANH MỤC SẢN PHẨM THỜI TRANG NAM)
-- Lưu trữ các danh mục sản phẩm (Áo sơ mi, Polo, Quần Tây, Quần Jeans, Áo Khoác,...)
-- ==============================================================================

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  sort_order int not null default 0
);
