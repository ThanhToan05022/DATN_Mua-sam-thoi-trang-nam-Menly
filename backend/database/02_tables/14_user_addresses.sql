-- ==============================================================================
-- BẢNG: USER_ADDRESSES (SỔ ĐỊA CHỈ GIAO HÀNG CỦA NGƯỜI DÙNG)
-- Lưu danh sách địa chỉ nhận hàng của khách hàng (Tỉnh/Thành, Quận/Huyện, Phường/Xã)
-- ==============================================================================

create table if not exists public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  recipient_name text not null,
  phone text not null,
  province text not null,
  district text not null,
  ward text not null,
  detail_address text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
