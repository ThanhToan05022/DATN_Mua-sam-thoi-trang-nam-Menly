-- ==============================================================================
-- 02. CUSTOM ENUMS
-- MenShop / Menly Supabase
-- Khởi tạo các kiểu dữ liệu liệt kê (Enums) cho đơn hàng, thanh toán và kho
-- ==============================================================================

do $$ begin
  -- 1. Trạng thái đơn hàng (Bao gồm core và marketplace return/refund)
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type order_status as enum (
      'pending_payment',
      'pending_confirmation',
      'paid',
      'processing',
      'shipping',
      'completed',
      'cancelled',
      'return_requested',
      'returning',
      'returned',
      'refunded'
    );
  else
    -- Bổ sung các giá trị mới nếu type đã tồn tại trước đó
    alter type order_status add value if not exists 'pending_confirmation';
    alter type order_status add value if not exists 'return_requested';
    alter type order_status add value if not exists 'returning';
    alter type order_status add value if not exists 'returned';
    alter type order_status add value if not exists 'refunded';
  end if;

  -- 2. Trạng thái thanh toán VNPay
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type payment_status as enum ('pending', 'success', 'failed');
  end if;

  -- 3. Lý do biến động tồn kho
  if not exists (select 1 from pg_type where typname = 'inventory_movement_reason') then
    create type inventory_movement_reason as enum (
      'order_created',
      'order_cancelled',
      'admin_restock',
      'admin_correction'
    );
  end if;
end $$;
