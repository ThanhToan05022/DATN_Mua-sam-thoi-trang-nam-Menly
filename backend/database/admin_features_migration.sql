-- ==============================================================================
-- MenShop - Admin Features & User Management Synchronization Migration
-- Dong bo: Profiles (is_locked, email, role user/admin), Indexes orders theo ngay,
-- Trigger dong bo auth.users, va Seed mac dinh admin@gmail.com (123456)
-- ==============================================================================

-- 1. Cap nhat bang profiles
alter table if exists public.profiles 
  add column if not exists email text,
  add column if not exists is_locked boolean not null default false;

-- Cap nhat check constraint cho role de ho tro ca 'admin', 'user', 'customer'
do $$
begin
  alter table public.profiles drop constraint if exists profiles_role_check;
  alter table public.profiles add constraint profiles_role_check check (role in ('customer', 'admin', 'user'));
exception
  when others then null;
end $$;

-- 2. Indexes toi uu truy van don hang theo ngay va trang thai cho Admin Dashboard
create index if not exists orders_created_at_idx on public.orders (created_at desc, id desc);
create index if not exists orders_status_created_idx on public.orders (status, created_at desc);

-- 3. Cap nhat trigger handle_new_user tu dong luu email va is_locked
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role, is_guest, is_active, is_locked)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'user'),
    coalesce(new.is_anonymous, false),
    true,
    false
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, profiles.full_name),
    role = coalesce(excluded.role, profiles.role);
  return new;
end $$;

-- 4. Seed tai khoan Admin mac dinh admin@gmail.com (mat khau: 123456)
do $$
declare
  admin_uid uuid := '00000000-0000-0000-0000-000000000001';
begin
  if not exists (select 1 from auth.users where email = 'admin@gmail.com') then
    insert into auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      role,
      aud
    ) values (
      admin_uid,
      '00000000-0000-0000-0000-000000000000',
      'admin@gmail.com',
      crypt('123456', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Admin MenShop","role":"admin"}',
      now(),
      now(),
      'authenticated',
      'authenticated'
    );
  end if;

  insert into public.profiles (id, email, full_name, role, is_guest, is_active, is_locked)
  values (
    (select id from auth.users where email = 'admin@gmail.com'),
    'admin@gmail.com',
    'Admin MenShop',
    'admin',
    false,
    true,
    false
  )
  on conflict (id) do update set
    email = 'admin@gmail.com',
    role = 'admin',
    is_active = true,
    is_locked = false;
end $$;
