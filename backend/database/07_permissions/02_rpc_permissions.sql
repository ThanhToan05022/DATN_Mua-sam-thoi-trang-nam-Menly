-- ==============================================================================
-- 02. RPC FUNCTION PERMISSIONS
-- Phân quyền thực thi các hàm Stored Procedure / RPC theo nguyên tắc bảo mật tối thiểu
-- ==============================================================================

-- 1. Hàm hệ thống và thanh toán: chỉ service_role (Backend API) được thực thi
revoke all on function public.create_order(uuid, jsonb, jsonb, text, int, text) from public, anon, authenticated;
grant execute on function public.create_order(uuid, jsonb, jsonb, text, int, text) to service_role;

revoke all on function public.settle_payment(text, boolean, text, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.settle_payment(text, boolean, text, text, text, jsonb) to service_role;

revoke all on function public.expire_pending_orders() from public, anon, authenticated;
grant execute on function public.expire_pending_orders() to service_role;

revoke all on function public.adjust_stock(uuid, int, inventory_movement_reason, text, uuid) from public, anon, authenticated;
grant execute on function public.adjust_stock(uuid, int, inventory_movement_reason, text, uuid) to service_role;

revoke all on function public.admin_update_order_status(uuid, order_status, text, uuid) from public, anon, authenticated;
grant execute on function public.admin_update_order_status(uuid, order_status, text, uuid) to service_role;

-- 2. Hàm tra cứu đơn hàng: người dùng ẩn danh (anon) và đã đăng nhập đều có thể gọi
grant execute on function public.track_order_by_code_phone(text, text) to anon, authenticated, service_role;

-- 3. Hàm hủy đơn hàng của người mua: chỉ tài khoản đã đăng nhập (authenticated) được gọi
grant execute on function public.cancel_order_by_buyer(uuid, uuid) to authenticated, service_role;
