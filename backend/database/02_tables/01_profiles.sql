-- ==============================================================================
-- BẢNG: PROFILES (HỒ SƠ NGƯỜI DÙNG & PHÂN QUYỀN)
-- Quản lý thông tin tài khoản người dùng, vai trò (admin, customer, user, seller),
-- trạng thái khóa tài khoản và khách vãng lai (guest).
-- ==============================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text,
  full_name text,
  phone text,
  avatar_url text,
  role text not null default 'user' check (role in ('customer', 'admin', 'user', 'seller')),
  is_guest boolean not null default false,
  is_active boolean not null default true,
  is_locked boolean not null default false,
  created_at timestamptz not null default now()
);

-- Đảm bảo các cột và ràng buộc cập nhật nếu bảng đã tồn tại
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists is_locked boolean not null default false;

do $$ begin
  alter table public.profiles drop constraint if exists profiles_role_check;
  alter table public.profiles add constraint profiles_role_check check (role in ('customer', 'admin', 'user', 'seller', 'staff'));
exception
  when others then null;
end $$;
