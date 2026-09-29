-- ==============================================================================
-- RPC FUNCTION: CREATE_ORDER
-- Đặt hàng toàn vẹn ACID:
-- 1. Chống duplicate đơn với Idempotency Key
-- 2. Khóa dòng biến thể (SELECT FOR UPDATE) để chống bán vượt tồn kho (race condition)
-- 3. Trừ tồn kho và ghi nhật ký inventory_movements
-- 4. Tạo bản ghi đơn hàng và chi tiết sản phẩm order_items
-- 5. Dọn dẹp giỏ hàng cart_items
-- ==============================================================================

create or replace function public.create_order(
  p_user_id uuid,
  p_items jsonb,
  p_ship jsonb,
  p_method text,
  p_shipping_fee int,
  p_idem_key text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_sub int := 0;
  r record;
  v record;
begin
  -- 1. Kiểm tra đơn hàng trùng lặp theo idempotency key
  select id into v_id from orders
   where user_id = p_user_id and idempotency_key = p_idem_key;
  if found then return v_id; end if;

  -- 2. Tạo đơn hàng mới
  insert into orders (
    code, user_id, status, payment_method, subtotal, total, shipping_fee,
    ship_name, ship_phone, ship_address, idempotency_key, expires_at
  )
  values (
    'MS' || to_char(now() at time zone 'Asia/Ho_Chi_Minh', 'YYMMDD')
         || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)),
    p_user_id,
    (case when p_method = 'vnpay' then 'pending_payment' else 'processing' end)::order_status,
    p_method, 0, 0, p_shipping_fee,
    p_ship->>'name', p_ship->>'phone', p_ship->>'address',
    p_idem_key,
    case when p_method = 'vnpay' then now() + interval '15 minutes' end
  ) returning id into v_id;

  -- 3. Xử lý từng sản phẩm trong đơn, khóa biến thể và trừ tồn kho
  for r in
    select (e->>'variant_id')::uuid as variant_id, (e->>'quantity')::int as qty
      from jsonb_array_elements(p_items) e
     order by variant_id
  loop
    select pv.id, pv.size, pv.color, pv.stock, p.name, p.price into v
      from product_variants pv join products p on p.id = pv.product_id
     where pv.id = r.variant_id and p.is_active
       for update of pv;

    if not found or v.stock < r.qty then
      raise exception 'OUT_OF_STOCK:%', r.variant_id;
    end if;

    -- Trừ tồn kho
    update product_variants set stock = stock - r.qty where id = r.variant_id;

    -- Ghi nhật ký biến động kho
    insert into inventory_movements (variant_id, change, reason, order_id, created_by, note)
    values (r.variant_id, -r.qty, 'order_created', v_id, p_user_id, 'Khách đặt hàng');

    -- Thêm chi tiết đơn hàng
    insert into order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_id, v.id, v.name, v.size, v.color, v.price, r.qty);

    v_sub := v_sub + v.price * r.qty;
  end loop;

  -- 4. Cập nhật lại tổng tiền đơn hàng
  update orders set subtotal = v_sub, total = v_sub + p_shipping_fee where id = v_id;

  -- 5. Xóa các món hàng tương ứng khỏi giỏ hàng
  delete from cart_items
   where user_id = p_user_id
     and variant_id in (select (e->>'variant_id')::uuid from jsonb_array_elements(p_items) e);

  return v_id;
end $$;

-- Phân quyền
revoke all on function public.create_order(uuid, jsonb, jsonb, text, int, text) from public, anon, authenticated;
grant execute on function public.create_order(uuid, jsonb, jsonb, text, int, text) to service_role;
