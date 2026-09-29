-- ==============================================================================
-- BẢNG: FLASH_SALES & FLASH_SALE_ITEMS (CHƯƠNG TRÌNH KHUYẾN MÃI CHỚP NHOÁNG)
-- Quản lý khung giờ Flash Sale, giới hạn số lượng và giá ưu đãi đặc biệt
-- ==============================================================================

create table if not exists public.flash_sales (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  is_active boolean not null default false
);

create table if not exists public.flash_sale_items (
  id uuid primary key default gen_random_uuid(),
  flash_sale_id uuid not null references public.flash_sales on delete cascade,
  variant_id uuid not null references public.product_variants on delete cascade,
  sale_price int not null check (sale_price > 0),
  quantity_limit int not null check (quantity_limit > 0),
  sold_count int not null default 0,
  unique (flash_sale_id, variant_id)
);
