-- ==============================================================================
-- 04. SEED PRODUCT VARIANTS (KÍCH CỠ M, L, XL - MÀU TRẮNG & ĐEN - SKU DUY NHẤT)
-- Tạo biến thể SKU cho toàn bộ 125 sản phẩm với màu Trắng & Đen, tồn kho thực tế 30-70 cái
-- ==============================================================================

insert into public.product_variants (product_id, size, color, sku, stock)
select
  p.id as product_id,
  s.size,
  c.color,
  'SKU-' || upper(substr(replace(p.slug, '-', ''), 1, 5)) || '-' || substr(p.id::text, 33, 4) || '-' || (case when c.color = 'Trắng' then 'W' else 'B' end) || '-' || s.size as sku,
  (30 + (random() * 40)::int) as stock
from public.products p
cross join (values ('M'), ('L'), ('XL')) as s(size)
cross join (values ('Trắng'), ('Đen')) as c(color)
on conflict (product_id, size, color) do update set
  sku = excluded.sku,
  stock = excluded.stock;
