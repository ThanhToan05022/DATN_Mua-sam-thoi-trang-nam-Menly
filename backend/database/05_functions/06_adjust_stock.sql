-- ==============================================================================
-- RPC FUNCTION: ADJUST_STOCK
-- Quản trị viên điều chỉnh tồn kho thủ công (nhập hàng mới hoặc kiểm kê sai lệch)
-- ==============================================================================

create or replace function public.adjust_stock(
  p_variant_id uuid,
  p_delta int,
  p_reason inventory_movement_reason,
  p_note text default null,
  p_admin_id uuid default null
) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_new int;
begin
  if p_reason not in ('admin_restock', 'admin_correction') then
    raise exception 'INVALID_REASON:%', p_reason;
  end if;

  update product_variants
     set stock = stock + p_delta
   where id = p_variant_id and stock + p_delta >= 0
   returning stock into v_new;

  if not found then
    raise exception 'INVALID_ADJUSTMENT:variant=% delta=%', p_variant_id, p_delta;
  end if;

  insert into inventory_movements (variant_id, change, reason, created_by, note)
  values (p_variant_id, p_delta, p_reason, p_admin_id, p_note);

  return v_new;
end $$;

-- Phân quyền
revoke all on function public.adjust_stock(uuid, int, inventory_movement_reason, text, uuid) from public, anon, authenticated;
grant execute on function public.adjust_stock(uuid, int, inventory_movement_reason, text, uuid) to service_role;
