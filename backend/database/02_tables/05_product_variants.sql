-- ==============================================================================
-- BẢNG: PRODUCT_VARIANTS (BIẾN THỂ SẢN PHẨM: KÍCH CỠ, MÀU SẮC, TỒN KHO)
-- Quản lý tồn kho thực tế ở mức SKU (Size: M, L, XL; Màu sắc: Đen, Trắng, Xanh...)
-- ==============================================================================

create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products on delete cascade,
  size text not null,
  color text not null,
  sku text not null unique,
  stock int not null default 0 check (stock >= 0),
  unique (product_id, size, color)
);
