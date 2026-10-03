-- ==============================================================================
-- MenShop - Cấp quyền cho service_role, anon, authenticated
-- Chạy đoạn này trong Supabase Dashboard -> SQL Editor để sửa lỗi 42501 permission denied
-- ==============================================================================

grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on all tables in schema public to postgres, anon, authenticated, service_role;
grant all on all sequences in schema public to postgres, anon, authenticated, service_role;
grant all on all routines in schema public to postgres, anon, authenticated, service_role;

alter default privileges in schema public grant all on tables to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on routines to postgres, anon, authenticated, service_role;
