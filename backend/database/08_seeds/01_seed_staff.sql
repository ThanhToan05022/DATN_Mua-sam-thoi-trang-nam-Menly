-- ==============================================================================
-- 01. SEED DEFAULT STAFF ACCOUNT
-- Tạo tài khoản nhân viên vận hành mặc định:
-- Email: staff@gmail.com
-- Mật khẩu: 123456
-- Role: staff
-- Quyền: Quản lý vận hành (đơn hàng, kiểm kho, sản phẩm), không có quyền quản lý người dùng
-- ==============================================================================

do $$
declare
  staff_uid uuid := '00000000-0000-0000-0000-000000000002';
begin
  -- 1. Tạo user trong auth.users nếu chưa tồn tại
  if not exists (select 1 from auth.users where email = 'staff@gmail.com') then
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
      staff_uid,
      '00000000-0000-0000-0000-000000000000',
      'staff@gmail.com',
      crypt('123456', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"],"role":"staff"}',
      '{"full_name":"Nhân viên Vận hành MenShop","role":"staff"}',
      now(),
      now(),
      'authenticated',
      'authenticated'
    );
  else
    update auth.users
       set encrypted_password = crypt('123456', gen_salt('bf')),
           raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"staff"}'::jsonb,
           raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"full_name":"Nhân viên Vận hành MenShop","role":"staff"}'::jsonb
     where email = 'staff@gmail.com';
  end if;

  -- 2. Đồng bộ profile tương ứng trong public.profiles
  insert into public.profiles (id, email, full_name, role, is_guest, is_active, is_locked)
  values (
    (select id from auth.users where email = 'staff@gmail.com'),
    'staff@gmail.com',
    'Nhân viên Vận hành MenShop',
    'staff',
    false,
    true,
    false
  )
  on conflict (id) do update set
    email = 'staff@gmail.com',
    role = 'staff',
    is_active = true,
    is_locked = false;
end $$;
