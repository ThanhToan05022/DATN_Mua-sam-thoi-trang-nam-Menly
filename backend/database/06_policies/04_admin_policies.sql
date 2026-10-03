-- ==============================================================================
-- 04. RLS POLICIES: QUYỀN QUẢN TRỊ VIÊN & NHÂN VIÊN VẬN HÀNH (STAFF & ADMIN)
-- - Quản trị viên (admin): Toàn quyền trên mọi bảng kể cả quản lý tài khoản người dùng
-- - Nhân viên (staff): Toàn quyền quản lý vận hành (đơn hàng, kho, sản phẩm, voucher, banner)
-- ==============================================================================

-- 1. Quản lý danh mục (Staff & Admin)
drop policy if exists "admin write categories" on public.categories;
create policy "admin write categories" on public.categories
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());

-- 2. Quản lý sản phẩm & biến thể & hình ảnh (Staff & Admin)
drop policy if exists "admin write products" on public.products;
create policy "admin write products" on public.products
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());

drop policy if exists "admin write product_variants" on public.product_variants;
create policy "admin write product_variants" on public.product_variants
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());

drop policy if exists "admin write product_images" on public.product_images;
create policy "admin write product_images" on public.product_images
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());

-- 3. Quản lý hồ sơ người dùng (CHỈ DÀNH CHO QUẢN TRỊ VIÊN ADMIN TOÀN QUYỀN)
drop policy if exists "admin read profiles" on public.profiles;
create policy "admin read profiles" on public.profiles
  for select to authenticated using (public.is_admin());

drop policy if exists "admin write profiles" on public.profiles;
create policy "admin write profiles" on public.profiles
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 4. Quản lý đơn hàng & chi tiết đơn & thanh toán (Staff & Admin)
drop policy if exists "admin read orders" on public.orders;
create policy "admin read orders" on public.orders
  for select to authenticated using (public.is_staff_or_admin());

drop policy if exists "admin write orders" on public.orders;
create policy "admin write orders" on public.orders
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());

drop policy if exists "admin read order_items" on public.order_items;
create policy "admin read order_items" on public.order_items
  for select to authenticated using (public.is_staff_or_admin());

drop policy if exists "admin read payments" on public.payments;
create policy "admin read payments" on public.payments
  for select to authenticated using (public.is_staff_or_admin());

-- 5. Quản lý banner & voucher & shop (Staff & Admin)
drop policy if exists "admin manage banners" on public.banners;
create policy "admin manage banners" on public.banners
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());

drop policy if exists "admin manage vouchers" on public.vouchers;
create policy "admin manage vouchers" on public.vouchers
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());

drop policy if exists "admin manage shops" on public.shops;
create policy "admin manage shops" on public.shops
  for all to authenticated using (public.is_staff_or_admin()) with check (public.is_staff_or_admin());
