-- ==============================================================================
-- FUNCTION: SET_USER_ROLE
-- Phân quyền tài khoản (customer, admin, user) đồng bộ giữa auth.users và public.profiles
-- Bảo mật: Chỉ được phép gọi từ service_role (Backend API)
-- ==============================================================================

create or replace function public.set_user_role(p_user_id uuid, p_role text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_role not in ('customer', 'admin', 'user', 'seller') then
    raise exception 'INVALID_ROLE:%', p_role;
  end if;

  update auth.users
     set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_role)
   where id = p_user_id;

  if not found then
    raise exception 'USER_NOT_FOUND:%', p_user_id;
  end if;

  update public.profiles set role = p_role where id = p_user_id;
end $$;

-- Phân quyền
revoke all on function public.set_user_role(uuid, text) from public, anon, authenticated;
grant execute on function public.set_user_role(uuid, text) to service_role;
