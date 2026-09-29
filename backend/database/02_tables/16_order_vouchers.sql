-- ==============================================================================
-- BẢNG: ORDER_VOUCHERS (LIÊN KẾT VOUCHER ĐÃ ÁP DỤNG CHO ĐƠN HÀNG)
-- Lưu lại mã voucher và số tiền giảm giá thực tế cho đơn hàng
-- ==============================================================================

create table if not exists public.order_vouchers (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  voucher_id uuid not null references public.vouchers,
  discount_amount int not null check (discount_amount >= 0),
  created_at timestamptz not null default now()
);
