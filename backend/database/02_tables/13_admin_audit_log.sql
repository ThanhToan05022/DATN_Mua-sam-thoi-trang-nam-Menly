-- ==============================================================================
-- BẢNG: ADMIN_AUDIT_LOG (NHẬT KÝ KIỂM TOÁN HÀNH VI QUẢN TRỊ VIÊN)
-- Ghi nhận các thao tác quan trọng: sửa giá, khóa tài khoản, duyệt shop, sửa đơn...
-- ==============================================================================

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);
