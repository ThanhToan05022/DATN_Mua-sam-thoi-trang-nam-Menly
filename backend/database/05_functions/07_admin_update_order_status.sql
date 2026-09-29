-- ==============================================================================
-- RPC FUNCTION: ADMIN_UPDATE_ORDER_STATUS
-- Admin cập nhật tiến trình đơn hàng (processing, shipping, completed, cancelled)
-- Kiểm tra state machine hợp lệ và tự động hoàn kho nếu đơn bị hủy
-- ==============================================================================

create or replace function public.admin_update_order_status(
  p_order_id uuid,
  p_new_status order_status,
  p_note text default null,
  p_admin_id uuid default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_old order_status;
begin
  if p_admin_id is not null and not exists (
    select 1 from profiles where id = p_admin_id and role = 'admin'
  ) then
    raise exception 'FORBIDDEN';
  end if;

  select status into v_old from orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND:%', p_order_id; end if;

  -- Kiểm tra chuyển đổi trạng thái hợp lệ
  if not (
    (v_old = 'pending_payment'      and p_new_status = 'cancelled') or
    (v_old = 'pending_confirmation' and p_new_status in ('processing', 'cancelled')) or
    (v_old = 'paid'                 and p_new_status in ('processing', 'cancelled')) or
    (v_old = 'processing'           and p_new_status in ('shipping', 'cancelled')) or
    (v_old = 'shipping'             and p_new_status in ('completed', 'cancelled')) or
    (v_old = 'return_requested'     and p_new_status in ('returning', 'cancelled')) or
    (v_old = 'returning'            and p_new_status in ('returned', 'completed')) or
    (v_old = 'returned'             and p_new_status in ('refunded'))
  ) then
    raise exception 'INVALID_TRANSITION:% -> %', v_old, p_new_status;
  end if;

  -- Nếu hủy đơn, tự động hoàn trả tồn kho cho tất cả sản phẩm trong đơn
  if p_new_status = 'cancelled' then
    insert into inventory_movements (variant_id, change, reason, order_id, created_by, note)
    select oi.variant_id, oi.quantity, 'order_cancelled', p_order_id, p_admin_id, coalesce(p_note, 'Hủy bởi admin')
      from order_items oi where oi.order_id = p_order_id;

    update product_variants pv set stock = pv.stock + oi.quantity
      from order_items oi where oi.variant_id = pv.id and oi.order_id = p_order_id;
  end if;

  update orders set status = p_new_status where id = p_order_id;

  insert into order_status_history (order_id, from_status, to_status, changed_by, note)
  values (p_order_id, v_old, p_new_status, p_admin_id, p_note);
end $$;

-- Phân quyền
revoke all on function public.admin_update_order_status(uuid, order_status, text, uuid) from public, anon, authenticated;
grant execute on function public.admin_update_order_status(uuid, order_status, text, uuid) to service_role;
