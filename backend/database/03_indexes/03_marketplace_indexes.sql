-- ==============================================================================
-- INDEXES: HỆ THỐNG MARKETPLACE (THANH TOÁN, TỒN KHO, ĐÁNH GIÁ, CHAT, THÔNG BÁO)
-- ==============================================================================

-- 1. Thanh toán theo đơn hàng
create index if not exists payments_order_idx on public.payments (order_id);

-- 2. Biến động tồn kho theo biến thể
create index if not exists inventory_var_idx on public.inventory_movements (variant_id);

-- 3. Đánh giá theo sản phẩm
create index if not exists reviews_product_idx on public.product_reviews (product_id, created_at desc);

-- 4. Trả hàng theo đơn hàng và shop
create index if not exists returns_order_idx on public.order_returns (order_id);
create index if not exists returns_shop_idx on public.order_returns (shop_id, status);

-- 5. Hội thoại và tin nhắn chat realtime
create index if not exists chat_conv_user_shop on public.chat_conversations (user_id, shop_id);
create index if not exists chat_msg_conv_idx on public.chat_messages (conversation_id, created_at);

-- 6. Thông báo người dùng chưa đọc
create index if not exists notif_user_idx on public.notifications (user_id, is_read, created_at desc);

-- 7. Tìm kiếm mã voucher đang hoạt động
create index if not exists vouchers_code_idx on public.vouchers (code) where is_active;

-- 8. Banner trang chủ theo thứ tự ưu tiên
create index if not exists banners_active_idx on public.banners (is_active, sort_order);
