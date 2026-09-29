-- ==============================================================================
-- BẢNG: ORDER_ITEMS (CHI TIẾT SẢN PHẨM TRONG ĐƠN HÀNG)
-- Lưu bản chụp bất biến (snapshot) tên sản phẩm, kích cỡ, màu sắc, đơn giá tại thời điểm đặt
-- ==============================================================================

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  variant_id uuid not null references public.product_variants,
  product_name text not null,
  size text not null,
  color text not null,
  unit_price int not null,
  quantity int not null check (quantity > 0)
);
