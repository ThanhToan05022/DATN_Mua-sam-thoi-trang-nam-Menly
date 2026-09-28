-- ==============================================================================
-- Menly - Supabase Marketplace V2 Migration
-- Bổ sung hệ sinh thái Sàn TMĐT đa người bán:
-- Shops, Addresses, Vouchers, Reviews, Returns, Chat, Notifications, Banners, Flash Sale
-- ==============================================================================

-- 1. CẬP NHẬT ENUM ORDER_STATUS
do $$ begin
  alter type order_status add value if not exists 'pending_confirmation';
  alter type order_status add value if not exists 'return_requested';
  alter type order_status add value if not exists 'returning';
  alter type order_status add value if not exists 'returned';
  alter type order_status add value if not exists 'refunded';
exception
  when duplicate_object then null;
end $$;

-- 2. BẢNG CỬA HÀNG (SHOPS / NGƯỜI BÁN)
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

-- Cập nhật vai trò trong bảng profiles hỗ trợ 'seller'
do $$ begin
  alter table public.profiles drop constraint if exists profiles_role_check;
  alter table public.profiles add constraint profiles_role_check check (role in ('customer', 'admin', 'user', 'seller'));
exception
  when others then null;
end $$;

-- 3. BỔ SUNG CỘT CHO BẢNG PRODUCTS (LIÊN KẾT SHOP & DUYỆT SẢN PHẨM)
alter table public.products add column if not exists shop_id uuid references public.shops on delete cascade;
alter table public.products add column if not exists approval_status text not null default 'approved' check (approval_status in ('pending', 'approved', 'rejected'));
alter table public.products add column if not exists rating_avg numeric(3,2) not null default 0.00;
alter table public.products add column if not exists rating_count int not null default 0;

-- 4. SỔ ĐỊA CHỈ NGƯỜI DÙNG (USER ADDRESSES)
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

-- 5. BỔ SUNG CỘT CHO ORDERS (HỖ TRỢ ĐƠN THEO SHOP)
alter table public.orders add column if not exists shop_id uuid references public.shops;
alter table public.orders add column if not exists parent_order_id uuid references public.orders(id) on delete cascade;

-- 6. MÃ GIẢM GIÁ (VOUCHERS) & ÁP DỤNG ĐƠN HÀNG (ORDER_VOUCHERS)
create table if not exists public.vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  shop_id uuid references public.shops on delete cascade, -- NULL = Voucher toàn sàn do Admin tạo
  title text not null,
  discount_type text not null check (discount_type in ('percentage', 'fixed_amount')),
  discount_value int not null check (discount_value > 0),
  min_order_value int not null default 0,
  max_discount int,
  usage_limit int not null default 100,
  used_count int not null default 0,
  start_date timestamptz not null default now(),
  end_date timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.order_vouchers (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  voucher_id uuid not null references public.vouchers,
  discount_amount int not null check (discount_amount >= 0),
  created_at timestamptz not null default now()
);

-- 7. ĐÁNH GIÁ & NHẬN XÉT SẢN PHẨM (PRODUCT REVIEWS)
create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products on delete cascade,
  order_item_id uuid not null references public.order_items,
  user_id uuid not null references auth.users,
  rating int not null check (rating between 1 and 5),
  comment text,
  images jsonb default '[]'::jsonb,
  reply_comment text,
  reply_at timestamptz,
  created_at timestamptz not null default now(),
  unique (order_item_id)
);

-- 8. TRẢ HÀNG & HOÀN TIỀN (ORDER RETURNS & DISPUTES)
create table if not exists public.order_returns (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  user_id uuid not null references auth.users,
  shop_id uuid not null references public.shops,
  reason text not null,
  proof_images jsonb default '[]'::jsonb,
  status text not null default 'requested' check (status in (
    'requested', 'shop_approved', 'shop_rejected', 'admin_dispute_review', 'refunded', 'rejected'
  )),
  refund_amount int not null,
  rejection_reason text,
  admin_resolution_note text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- 9. YÊU THÍCH (WISHLIST) & THEO DÕI SHOP (FOLLOWERS)
create table if not exists public.wishlists (
  user_id uuid not null references auth.users on delete cascade,
  product_id uuid not null references public.products on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists public.shop_followers (
  user_id uuid not null references auth.users on delete cascade,
  shop_id uuid not null references public.shops on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, shop_id)
);

-- 10. CHAT THỜI GIAN THỰC (CONVERSATIONS & MESSAGES)
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

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations on delete cascade,
  sender_id uuid not null references auth.users,
  message_type text not null default 'text' check (message_type in ('text', 'image')),
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- 11. THÔNG BÁO ĐẨY (NOTIFICATIONS)
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('order', 'promo', 'system')),
  data jsonb default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- 12. BANNER QUẢNG CÁO TRANG CHỦ
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

-- 13. FLASH SALE & SẢN PHẨM GIẢM SỐC
create table if not exists public.flash_sales (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  is_active boolean not null default false
);

create table if not exists public.flash_sale_items (
  id uuid primary key default gen_random_uuid(),
  flash_sale_id uuid not null references public.flash_sales on delete cascade,
  variant_id uuid not null references public.product_variants on delete cascade,
  sale_price int not null check (sale_price > 0),
  quantity_limit int not null check (quantity_limit > 0),
  sold_count int not null default 0,
  unique (flash_sale_id, variant_id)
);

-- 14. INDEXES TỐI ƯU HIỆU NĂNG
create index if not exists products_shop_idx     on public.products (shop_id, created_at desc);
create index if not exists orders_shop_idx       on public.orders (shop_id, created_at desc);
create index if not exists reviews_product_idx   on public.product_reviews (product_id, created_at desc);
create index if not exists returns_order_idx     on public.order_returns (order_id);
create index if not exists returns_shop_idx      on public.order_returns (shop_id, status);
create index if not exists chat_conv_user_shop   on public.chat_conversations (user_id, shop_id);
create index if not exists chat_msg_conv_idx     on public.chat_messages (conversation_id, created_at);
create index if not exists notif_user_idx        on public.notifications (user_id, is_read, created_at desc);
create index if not exists vouchers_code_idx     on public.vouchers (code) where is_active;
create index if not exists banners_active_idx    on public.banners (is_active, sort_order);

-- 15. TRIGGER TỰ ĐỘNG TÍNH ĐIỂM UY TÍN (RATING) CHO SẢN PHẨM & SHOP
create or replace function public.update_product_and_shop_rating()
returns trigger language plpgsql security definer as $$
declare
  v_shop_id uuid;
begin
  -- Cập nhật rating sản phẩm
  update public.products
  set rating_avg = round((select coalesce(avg(rating), 0) from public.product_reviews where product_id = new.product_id), 2),
      rating_count = (select count(*) from public.product_reviews where product_id = new.product_id)
  where id = new.product_id
  returning shop_id into v_shop_id;

  -- Cập nhật rating shop
  if v_shop_id is not null then
    update public.shops
    set rating_avg = round((
      select coalesce(avg(r.rating), 0)
      from public.product_reviews r
      join public.products p on p.id = r.product_id
      where p.shop_id = v_shop_id
    ), 2),
    rating_count = (
      select count(*)
      from public.product_reviews r
      join public.products p on p.id = r.product_id
      where p.shop_id = v_shop_id
    )
    where id = v_shop_id;
  end if;

  return new;
end $$;

drop trigger if exists on_product_review_added on public.product_reviews;
create trigger on_product_review_added
after insert on public.product_reviews
for each row execute function public.update_product_and_shop_rating();

-- 16. RPC: NGƯỜI MUA TỰ HỦY ĐƠN HÀNG (KHI CHƯA XÁC NHẬN) VÀ HOÀN TỒN KHO
create or replace function public.cancel_order_by_buyer(p_order_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_item record;
begin
  select * into v_order from public.orders where id = p_order_id and user_id = p_user_id for update;
  if not found then
    raise exception 'Không tìm thấy đơn hàng hoặc bạn không có quyền';
  end if;

  if v_order.status not in ('pending_payment', 'pending_confirmation') then
    raise exception 'Đơn hàng đã được người bán xử lý đóng gói, không thể tự hủy';
  end if;

  -- Hoàn lại số lượng tồn kho cho các biến thể
  for v_item in select variant_id, quantity from public.order_items where order_id = p_order_id loop
    update public.product_variants
    set stock = stock + v_item.quantity
    where id = v_item.variant_id;

    insert into public.inventory_logs (variant_id, delta, reason, reference_id)
    values (v_item.variant_id, v_item.quantity, 'order_cancelled', p_order_id);
  end loop;

  update public.orders set status = 'cancelled' where id = p_order_id;
end $$;

-- 17. RPC: CRON TỰ ĐỘNG HỦY CÁC ĐƠN VNPAY QUÁ HẠN 15 PHÚT CHƯA THANH TOÁN
create or replace function public.release_expired_orders()
returns int language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_item record;
  v_count int := 0;
begin
  for v_order in
    select id from public.orders
    where status = 'pending_payment'
      and expires_at is not null
      and expires_at < now()
    for update skip locked
  loop
    for v_item in select variant_id, quantity from public.order_items where order_id = v_order.id loop
      update public.product_variants set stock = stock + v_item.quantity where id = v_item.variant_id;
      insert into public.inventory_logs (variant_id, delta, reason, reference_id)
      values (v_item.variant_id, v_item.quantity, 'order_cancelled', v_order.id);
    end loop;

    update public.orders set status = 'cancelled' where id = v_order.id;
    v_count := v_count + 1;
  end loop;

  return v_count;
end $$;
