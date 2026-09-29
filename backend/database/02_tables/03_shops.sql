-- ==============================================================================
-- BẢNG: SHOPS (CỬA HÀNG / NGƯỜI BÁN TRÊN SÀN TMĐT)
-- Quản lý thông tin gian hàng của seller, logo, banner, điểm đánh giá uy tín
-- ==============================================================================

create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users on delete cascade,
  name text not null unique,
  slug text not null unique,
  description text,
  logo_url text,
  banner_url text,
  phone text not null,
  address text not null,
  status text not null default 'pending' check (status in ('pending', 'active', 'suspended', 'rejected')),
  rating_avg numeric(3,2) not null default 0.00 check (rating_avg between 0 and 5),
  rating_count int not null default 0,
  created_at timestamptz not null default now()
);
