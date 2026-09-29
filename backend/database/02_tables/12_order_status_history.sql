-- ==============================================================================
-- BẢNG: ORDER_STATUS_HISTORY (LỊCH SỬ CHUYỂN TRẠNG THÁI ĐƠN HÀNG)
-- Lưu dấu vết thời gian thay đổi trạng thái đơn hàng và người thực hiện (admin/hệ thống)
-- ==============================================================================

create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  from_status order_status,
  to_status order_status not null,
  changed_by uuid references auth.users,
  note text,
  created_at timestamptz not null default now()
);
