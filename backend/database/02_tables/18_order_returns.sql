-- ==============================================================================
-- BẢNG: ORDER_RETURNS (YÊU CẦU TRẢ HÀNG & HOÀN TIỀN)
-- Quản lý quy trình đổi trả hàng, hình ảnh bằng chứng, xét duyệt của người bán & admin
-- ==============================================================================

create table if not exists public.order_returns (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  user_id uuid not null references auth.users,
  shop_id uuid not null references public.shops,
  reason text not null,
  proof_images jsonb default '[]'::jsonb,
  status text not null default 'requested' check (status in (
    'requested', 'shop_approved', 'shop_rejected', 'admin_dispute_review', 'refunded', 'rejected'
  )),
  refund_amount int not null,
  rejection_reason text,
  admin_resolution_note text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
