-- ==============================================================================
-- 03. RLS POLICIES: DỮ LIỆU CÁ NHÂN CỦA NGƯỜI DÙNG (USER OWNS DATA)
-- Khách hàng chỉ được phép xem & chỉnh sửa thông tin thuộc về chính mình
-- ==============================================================================

-- 1. Xem và sửa hồ sơ cá nhân
drop policy if exists "own profile read" on public.profiles;
create policy "own profile read" on public.profiles
  for select to authenticated using (id = (select auth.uid()));

drop policy if exists "own profile update" on public.profiles;
create policy "own profile update" on public.profiles
  for update to authenticated using (id = (select auth.uid()));

-- 2. Quản lý giỏ hàng của chính mình
drop policy if exists "own cart read" on public.cart_items;
create policy "own cart read" on public.cart_items
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "own cart modify" on public.cart_items;
create policy "own cart modify" on public.cart_items
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- 3. Xem danh sách đơn hàng của chính mình
drop policy if exists "own orders read" on public.orders;
create policy "own orders read" on public.orders
  for select to authenticated using (user_id = (select auth.uid()));

-- 4. Quản lý địa chỉ giao hàng của chính mình
drop policy if exists "own addresses all" on public.user_addresses;
create policy "own addresses all" on public.user_addresses
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- 5. Quản lý sản phẩm yêu thích (wishlist)
drop policy if exists "own wishlists all" on public.wishlists;
create policy "own wishlists all" on public.wishlists
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- 6. Quản lý thông báo cá nhân
drop policy if exists "own notifications read" on public.notifications;
create policy "own notifications read" on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));
