-- ==============================================================================
-- TRIGGER & FUNCTION: HANDLE_USER_ANONYMITY_CHANGE
-- Tự động cập nhật cờ is_guest trong profiles khi tài khoản ẩn danh chuyển thành chính thức
-- ==============================================================================

create or replace function public.handle_user_anonymity_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.is_anonymous is distinct from old.is_anonymous then
    update public.profiles set is_guest = coalesce(new.is_anonymous, false) where id = new.id;
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_anonymity_change on auth.users;
create trigger on_auth_user_anonymity_change
after update of is_anonymous on auth.users
for each row execute function public.handle_user_anonymity_change();
