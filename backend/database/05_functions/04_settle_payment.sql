-- ==============================================================================
-- RPC FUNCTION: SETTLE_PAYMENT
-- Xử lý xác nhận thanh toán VNPay IPN webhook:
-- Cập nhật giao dịch payments, và chuyển trạng thái đơn hàng orders sang 'paid'
-- ==============================================================================

create or replace function public.settle_payment(
  p_txn_ref text,
  p_success boolean,
  p_txn_no text,
  p_bank text,
  p_code text,
  p_raw jsonb
) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_order uuid;
begin
  update payments
     set status = (case when p_success then 'success' else 'failed' end)::payment_status,
         provider_txn_no = p_txn_no,
         bank_code = p_bank,
         response_code = p_code,
         raw = p_raw,
         paid_at = case when p_success then now() end
   where txn_ref = p_txn_ref and status = 'pending'
   returning order_id into v_order;

  if not found then
    return 'already';
  end if;

  if p_success then
    update orders set status = 'paid' where id = v_order and status = 'pending_payment';
  end if;

  return 'ok';
end $$;

-- Phân quyền
revoke all on function public.settle_payment(text, boolean, text, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.settle_payment(text, boolean, text, text, text, jsonb) to service_role;
