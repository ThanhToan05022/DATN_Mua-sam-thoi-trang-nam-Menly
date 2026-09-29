-- ==============================================================================
-- BẢNG: PAYMENTS (GIAO DỊCH CỔNG THANH TOÁN VNPAY)
-- Quản lý mã giao dịch đối soát txn_ref, số tiền, mã ngân hàng, phản hồi IPN
-- ==============================================================================

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders,
  provider text not null default 'vnpay',
  txn_ref text not null unique,
  amount int not null,
  status payment_status not null default 'pending',
  provider_txn_no text,
  bank_code text,
  response_code text,
  raw jsonb,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);
