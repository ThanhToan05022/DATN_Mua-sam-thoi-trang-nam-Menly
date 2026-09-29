-- ==============================================================================
-- 02. SEED CATEGORIES (5 DANH MỤC THỜI TRANG NAM CHUẨN UUID)
-- ==============================================================================

insert into public.categories (id, name, slug, sort_order) values
  ('c0000000-0000-0000-0000-000000000001', 'Áo Sơ Mi Nam', 'ao-so-mi-nam', 1),
  ('c0000000-0000-0000-0000-000000000002', 'Áo Polo & T-Shirt', 'ao-polo-t-shirt', 2),
  ('c0000000-0000-0000-0000-000000000003', 'Quần Tây & Kaki', 'quan-tay-kaki', 3),
  ('c0000000-0000-0000-0000-000000000004', 'Quần Jeans Nam', 'quan-jeans-nam', 4),
  ('c0000000-0000-0000-0000-000000000005', 'Áo Khoác & Blazer', 'ao-khoac-blazer', 5)
on conflict (slug) do update set
  id = excluded.id,
  name = excluded.name,
  sort_order = excluded.sort_order;
