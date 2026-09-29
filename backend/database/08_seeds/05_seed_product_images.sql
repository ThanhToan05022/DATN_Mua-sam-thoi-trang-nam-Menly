-- ==============================================================================
-- 05. SEED PRODUCT IMAGES (THƯ VIỆN ẢNH SẢN PHẨM)
-- Đồng bộ ảnh đại diện thumbnail_url vào bảng product_images
-- ==============================================================================

insert into public.product_images (product_id, url, sort_order)
select
  p.id,
  p.thumbnail_url,
  1
from public.products p
where not exists (
  select 1 from public.product_images pi where pi.product_id = p.id
);
