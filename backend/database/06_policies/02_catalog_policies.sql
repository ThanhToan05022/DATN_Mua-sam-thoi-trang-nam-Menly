-- ==============================================================================
-- 02. RLS POLICIES: CATALOG ĐỌC DỮ LIỆU CÔNG KHAI (ANON & AUTHENTICATED)
-- Cho phép khách vãng lai và người dùng đã đăng nhập xem danh mục, sản phẩm, hình ảnh, banner
-- ==============================================================================

-- 1. Đọc danh mục sản phẩm
drop policy if exists "catalog read" on public.categories;
create policy "catalog read" on public.categories
  for select to anon, authenticated using (true);

-- 2. Đọc sản phẩm đang hoạt động
drop policy if exists "catalog read" on public.products;
create policy "catalog read" on public.products
  for select to anon, authenticated using (is_active);

-- 3. Đọc biến thể sản phẩm
drop policy if exists "catalog read" on public.product_variants;
create policy "catalog read" on public.product_variants
  for select to anon, authenticated using (true);

-- 4. Đọc hình ảnh sản phẩm
drop policy if exists "catalog read" on public.product_images;
create policy "catalog read" on public.product_images
  for select to anon, authenticated using (true);

-- 5. Đọc banner quảng cáo đang hoạt động
drop policy if exists "banners public read" on public.banners;
create policy "banners public read" on public.banners
  for select to anon, authenticated using (is_active);

-- 6. Đọc thông tin cửa hàng đang hoạt động
drop policy if exists "shops public read" on public.shops;
create policy "shops public read" on public.shops
  for select to anon, authenticated using (status = 'active');

-- 7. Đọc đánh giá sản phẩm
drop policy if exists "reviews public read" on public.product_reviews;
create policy "reviews public read" on public.product_reviews
  for select to anon, authenticated using (true);
