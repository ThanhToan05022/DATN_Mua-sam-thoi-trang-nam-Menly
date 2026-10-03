-- ==============================================================================
-- RPC FUNCTION: CANCEL_ORDER_BY_BUYER
-- Khách hàng tự hủy đơn hàng khi đơn chưa được shop đóng gói / xác nhận:
-- Tự động hoàn trả số lượng tồn kho cho các biến thể sản phẩm trong đơn.
-- ==============================================================================

create or replace function public.cancel_order_by_buyer(p_order_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_item record;
begin
  select * into v_order from public.orders where id = p_order_id and user_id = p_user_id for update;
  if not found then
    raise exception 'Không tìm thấy đơn hàng hoặc bạn không có quyền hủy';
  end if;

  if v_order.status not in ('pending_payment', 'pending_confirmation') then
    raise exception 'Đơn hàng đã được người bán xử lý đóng gói, không thể tự hủy';
  end if;

  -- Hoàn lại số lượng tồn kho cho các biến thể
  for v_item in select variant_id, quantity from public.order_items where order_id = p_order_id loop
    update public.product_variants
       set stock = stock + v_item.quantity
     where id = v_item.variant_id;

    insert into public.inventory_movements (variant_id, change, reason, order_id, created_by, note)
    values (v_item.variant_id, v_item.quantity, 'order_cancelled', p_order_id, p_user_id, 'Khách hàng tự hủy đơn');
  end loop;

  update public.orders set status = 'cancelled' where id = p_order_id;

  insert into public.order_status_history (order_id, from_status, to_status, changed_by, note)
  values (p_order_id, v_order.status, 'cancelled', p_user_id, 'Khách hàng tự hủy đơn');
end $$;

-- Phân quyền
revoke all on function public.cancel_order_by_buyer(uuid, uuid) from public, anon;
grant execute on function public.cancel_order_by_buyer(uuid, uuid) to authenticated, service_role;
