-- ==============================================================================
-- FUNCTION: IS_ADMIN
-- Kiểm tra token người dùng có quyền Admin thông qua auth.jwt() app_metadata
-- Sử dụng trong các chính sách Row Level Security (RLS)
-- ==============================================================================

create or replace function public.is_admin() returns boolean
language sql stable as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

-- FUNCTION: IS_STAFF_OR_ADMIN
-- Kiểm tra token người dùng có quyền Nhân viên hoặc Admin để thực hiện các thao tác vận hành
create or replace function public.is_staff_or_admin() returns boolean
language sql stable as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'role') in ('admin', 'staff'),
    false
  );
$$;

