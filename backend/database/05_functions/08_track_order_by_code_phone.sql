-- ==============================================================================
-- RPC FUNCTION: TRACK_ORDER_BY_CODE_PHONE
-- Tra cứu đơn hàng công khai: Khách hàng không cần đăng nhập vẫn có thể
-- tra cứu trạng thái đơn hàng thông qua Mã Đơn Hàng + Số Điện Thoại
-- ==============================================================================

create or replace function public.track_order_by_code_phone(p_code text, p_phone text)
returns table (
  id uuid,
  code text,
  status order_status,
  total int,
  payment_method text,
  created_at timestamptz,
  items jsonb
)
language sql security definer set search_path = public as $$
  select
    o.id,
    o.code,
    o.status,
    o.total,
    o.payment_method,
    o.created_at,
    (
      select jsonb_agg(jsonb_build_object(
        'productName', oi.product_name,
        'size', oi.size,
        'color', oi.color,
        'quantity', oi.quantity,
        'unitPrice', oi.unit_price
      ))
      from order_items oi
      where oi.order_id = o.id
    ) as items
  from orders o
  where o.code = p_code and o.ship_phone = p_phone;
$$;

-- Phân quyền cho anon và service_role
revoke all on function public.track_order_by_code_phone(text, text) from public, authenticated;
grant execute on function public.track_order_by_code_phone(text, text) to anon, authenticated, service_role;
