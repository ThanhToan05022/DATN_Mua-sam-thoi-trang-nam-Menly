-- ==============================================================================
-- BẢNG: PRODUCT_IMAGES (THƯ VIỆN HÌNH ẢNH SẢN PHẨM)
-- Lưu danh sách các góc chụp của sản phẩm và thứ tự hiển thị (sort_order)
-- ==============================================================================

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products on delete cascade,
  url text not null,
  sort_order int not null default 0
);
