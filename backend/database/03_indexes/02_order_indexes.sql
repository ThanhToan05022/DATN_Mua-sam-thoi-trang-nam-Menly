-- ==============================================================================
-- INDEXES: ĐƠN HÀNG & LỊCH SỬ ĐƠN HÀNG (TỐI ƯU ADMIN & CUSTOMER QUERY)
-- ==============================================================================

-- 1. Lọc đơn hàng của khách hàng theo thời gian
create index if not exists orders_user_idx on public.orders (user_id, created_at desc, id desc);

-- 2. Tối ưu thống kê và phân trang dashboard quản trị viên
create index if not exists orders_created_at_idx on public.orders (created_at desc, id desc);

-- 3. Lọc nhanh đơn hàng theo trạng thái (status)
create index if not exists orders_status_created_idx on public.orders (status, created_at desc);

-- 4. Tối ưu lấy chi tiết sản phẩm theo order_id
create index if not exists order_items_order_idx on public.order_items (order_id);

-- 5. Lọc đơn hàng theo gian hàng (shop)
create index if not exists orders_shop_idx on public.orders (shop_id, created_at desc);

-- 6. Lịch sử thay đổi trạng thái đơn
create index if not exists order_history_idx on public.order_status_history (order_id);
