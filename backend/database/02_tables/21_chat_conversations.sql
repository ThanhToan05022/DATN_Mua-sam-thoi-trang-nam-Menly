-- ==============================================================================
-- BẢNG: CHAT_CONVERSATIONS (HỘI THOẠI CHAT KHÁCH HÀNG & GIAN HÀNG)
-- Quản lý phòng chat trực tiếp giữa người mua và shop
-- ==============================================================================

create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  shop_id uuid not null references public.shops on delete cascade,
  last_message text,
  last_message_at timestamptz default now(),
  unread_user_count int not null default 0,
  unread_shop_count int not null default 0,
  created_at timestamptz not null default now(),
  unique (user_id, shop_id)
);
