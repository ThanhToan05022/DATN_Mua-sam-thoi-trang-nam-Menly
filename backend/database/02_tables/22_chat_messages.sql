-- ==============================================================================
-- BẢNG: CHAT_MESSAGES (TIN NHẮN CHAT REALTIME)
-- Hỗ trợ tin nhắn văn bản và hình ảnh đính kèm, trạng thái đã xem (is_read)
-- ==============================================================================

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations on delete cascade,
  sender_id uuid not null references auth.users,
  message_type text not null default 'text' check (message_type in ('text', 'image')),
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
