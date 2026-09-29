-- ==============================================================================
-- 01. SEED DEFAULT ADMIN ACCOUNT
-- Tạo tài khoản quản trị viên mặc định:
-- Email: admin@gmail.com
-- Mật khẩu: 123456
-- Role: admin
-- ==============================================================================

do $$
declare
  admin_uid uuid := '00000000-0000-0000-0000-000000000001';
begin
  -- 1. Tạo user trong auth.users nếu chưa tồn tại
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
      '{"provider":"email","providers":["email"],"role":"admin"}',
      '{"full_name":"Admin MenShop","role":"admin"}',
      now(),
      now(),
      'authenticated',
      'authenticated'
    );
  else
    update auth.users
       set encrypted_password = crypt('123456', gen_salt('bf')),
           raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb,
           raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"full_name":"Admin MenShop","role":"admin"}'::jsonb
     where email = 'admin@gmail.com';
  end if;

  -- 2. Đồng bộ profile tương ứng trong public.profiles
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
