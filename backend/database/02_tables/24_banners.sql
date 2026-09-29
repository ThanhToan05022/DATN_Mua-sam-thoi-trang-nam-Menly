-- ==============================================================================
-- BẢNG: BANNERS (BANNER QUẢNG CÁO & SLIDER TRANG CHỦ)
-- Quản lý hình ảnh banner hiển thị trên ứng dụng mobile và trang web
-- ==============================================================================

create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text not null,
  link_url text,
  sort_order int not null default 0,
  is_active boolean not null default true,
  start_date timestamptz not null default now(),
  end_date timestamptz not null
);
