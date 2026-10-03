-- ==============================================================================
-- BẢNG: INVENTORY_MOVEMENTS (NHẬT KÝ BIẾN ĐỘNG TỒN KHO)
-- Ghi lại mọi lần tăng/giảm tồn kho: đặt hàng, hủy đơn hoàn kho, nhập hàng, điều chỉnh
-- ==============================================================================

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants on delete cascade,
  change int not null,
  reason inventory_movement_reason not null,
  order_id uuid references public.orders,
  created_by uuid references auth.users,
  note text,
  created_at timestamptz not null default now()
);
