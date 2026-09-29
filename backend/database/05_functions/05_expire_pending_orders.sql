-- ==============================================================================
-- RPC FUNCTION: EXPIRE_PENDING_ORDERS
-- Tự động hủy các đơn hàng thanh toán VNPay hết hạn (sau 15 phút) chưa hoàn tất:
-- Chuyển trạng thái đơn sang 'cancelled', tự động hoàn lại tồn kho biến thể
-- và ghi nhận lý do 'order_cancelled' vào inventory_movements.
-- ==============================================================================

create or replace function public.expire_pending_orders() returns int
language plpgsql security definer set search_path = public as $$
declare
  n int;
begin
  with c as (
    update orders set status = 'cancelled'
     where status = 'pending_payment' and expires_at < now()
    returning id
  ), s as (
    select oi.variant_id, sum(oi.quantity)::int as q, c.id as order_id
      from order_items oi join c on c.id = oi.order_id
     group by oi.variant_id, c.id
  ), u as (
    update product_variants pv set stock = pv.stock + s.q
      from s where pv.id = s.variant_id
    returning 1
  ), m as (
    insert into inventory_movements (variant_id, change, reason, order_id, note)
    select s.variant_id, s.q, 'order_cancelled', s.order_id, 'Đơn VNPay hết hạn tự động hoàn kho'
    from s
    returning 1
  )
  select count(*) into n from c;
  return n;
end $$;

-- Phân quyền
revoke all on function public.expire_pending_orders() from public, anon, authenticated;
grant execute on function public.expire_pending_orders() to service_role;
