-- ==============================================================================
-- MenShop - Supabase Complete Setup Migration
-- Bao gom: Schema, Indexes, RLS, Roles, RPCs, Inventory/Audit, Guest Tracking
-- ==============================================================================

-- 1. EXTENSIONS & TYPES
create extension if not exists pg_trgm with schema extensions;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type order_status as enum
      ('pending_payment', 'paid', 'processing', 'shipping', 'completed', 'cancelled');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type payment_status as enum ('pending', 'success', 'failed');
  end if;
  if not exists (select 1 from pg_type where typname = 'inventory_movement_reason') then
    create type inventory_movement_reason as enum
      ('order_created', 'order_cancelled', 'admin_restock', 'admin_correction');
  end if;
end $$;

-- 2. TABLES
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  email text,
  full_name text,
  phone text,
  role text not null default 'user' check (role in ('customer', 'admin', 'user')),
  is_guest boolean not null default false,
  is_active boolean not null default true,
  is_locked boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  sort_order int not null default 0
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references categories,
  name text not null,
  slug text not null unique,
  description text,
  price int not null check (price >= 0),
  thumbnail_url text,
  search_text text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products on delete cascade,
  size text not null,
  color text not null,
  sku text not null unique,
  stock int not null default 0 check (stock >= 0),
  unique (product_id, size, color)
);

create table if not exists product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products on delete cascade,
  url text not null,
  sort_order int not null default 0
);

create table if not exists cart_items (
  user_id uuid not null references auth.users on delete cascade,
  variant_id uuid not null references product_variants on delete cascade,
  quantity int not null check (quantity between 1 and 20),
  updated_at timestamptz not null default now(),
  primary key (user_id, variant_id)
);

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  user_id uuid not null references auth.users,
  status order_status not null default 'pending_payment',
  payment_method text not null check (payment_method in ('cod', 'vnpay')),
  subtotal int not null,
  shipping_fee int not null default 0,
  total int not null,
  ship_name text not null,
  ship_phone text not null,
  ship_address text not null,
  idempotency_key text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders on delete cascade,
  variant_id uuid not null references product_variants,
  product_name text not null,
  size text not null,
  color text not null,
  unit_price int not null,
  quantity int not null check (quantity > 0)
);

create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders,
  provider text not null default 'vnpay',
  txn_ref text not null unique,
  amount int not null,
  status payment_status not null default 'pending',
  provider_txn_no text,
  bank_code text,
  response_code text,
  raw jsonb,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create table if not exists inventory_movements (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references product_variants on delete cascade,
  change int not null,
  reason inventory_movement_reason not null,
  order_id uuid references orders,
  created_by uuid references auth.users,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders on delete cascade,
  from_status order_status,
  to_status order_status not null,
  changed_by uuid references auth.users,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

-- 3. INDEXES
create index if not exists products_newest_idx   on products (created_at, id) where is_active;
create index if not exists products_price_idx    on products (price, id)      where is_active;
create index if not exists products_category_idx on products (category_id, created_at, id) where is_active;
create index if not exists products_search_trgm  on products using gin (search_text extensions.gin_trgm_ops);
create index if not exists variants_product_idx  on product_variants (product_id);
create index if not exists orders_user_idx       on orders (user_id, created_at, id);
create index if not exists orders_created_at_idx on orders (created_at desc, id desc);
create index if not exists orders_status_created_idx on orders (status, created_at desc);
create index if not exists order_items_order_idx on order_items (order_id);
create index if not exists payments_order_idx    on payments (order_id);
create index if not exists inventory_var_idx     on inventory_movements (variant_id);
create index if not exists order_history_idx     on order_status_history (order_id);

-- 4. TRIGGERS & PROFILE FUNCTIONS
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
    full_name = coalesce(excluded.full_name, profiles.full_name);
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.handle_user_anonymity_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.is_anonymous is distinct from old.is_anonymous then
    update public.profiles set is_guest = coalesce(new.is_anonymous, false) where id = new.id;
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_anonymity_change on auth.users;
create trigger on_auth_user_anonymity_change
after update of is_anonymous on auth.users
for each row execute function public.handle_user_anonymity_change();

-- 5. ADMIN ROLE HELPERS
create or replace function public.is_admin() returns boolean
language sql stable as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

create or replace function public.set_user_role(p_user_id uuid, p_role text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_role not in ('customer', 'admin') then
    raise exception 'INVALID_ROLE:%', p_role;
  end if;
  update auth.users
     set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_role)
   where id = p_user_id;
  if not found then
    raise exception 'USER_NOT_FOUND:%', p_user_id;
  end if;
  update public.profiles set role = p_role where id = p_user_id;
end $$;

revoke all on function public.set_user_role(uuid, text) from public, anon, authenticated;
grant execute on function public.set_user_role(uuid, text) to service_role;

-- 6. RPC PROCEDURES (create_order, settle_payment, expire_pending_orders, adjust_stock, admin_update_order_status, track_order_by_code_phone)
create or replace function public.create_order(
  p_user_id uuid, p_items jsonb, p_ship jsonb,
  p_method text, p_shipping_fee int, p_idem_key text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_sub int := 0;
  r record;
  v record;
begin
  select id into v_id from orders
   where user_id = p_user_id and idempotency_key = p_idem_key;
  if found then return v_id; end if;

  insert into orders (code, user_id, status, payment_method, subtotal, total, shipping_fee,
                      ship_name, ship_phone, ship_address, idempotency_key, expires_at)
  values (
    'MS' || to_char(now() at time zone 'Asia/Ho_Chi_Minh', 'YYMMDD')
         || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)),
    p_user_id,
    (case when p_method = 'vnpay' then 'pending_payment' else 'processing' end)::order_status,
    p_method, 0, 0, p_shipping_fee,
    p_ship->>'name', p_ship->>'phone', p_ship->>'address',
    p_idem_key,
    case when p_method = 'vnpay' then now() + interval '15 minutes' end
  ) returning id into v_id;

  for r in
    select (e->>'variant_id')::uuid as variant_id, (e->>'quantity')::int as qty
      from jsonb_array_elements(p_items) e
     order by variant_id
  loop
    select pv.id, pv.size, pv.color, pv.stock, p.name, p.price into v
      from product_variants pv join products p on p.id = pv.product_id
     where pv.id = r.variant_id and p.is_active
       for update of pv;
    if not found or v.stock < r.qty then
      raise exception 'OUT_OF_STOCK:%', r.variant_id;
    end if;
    update product_variants set stock = stock - r.qty where id = r.variant_id;
    insert into inventory_movements (variant_id, change, reason, order_id, created_by, note)
    values (r.variant_id, -r.qty, 'order_created', v_id, p_user_id, 'Khach dat hang');

    insert into order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_id, v.id, v.name, v.size, v.color, v.price, r.qty);
    v_sub := v_sub + v.price * r.qty;
  end loop;

  update orders set subtotal = v_sub, total = v_sub + p_shipping_fee where id = v_id;
  delete from cart_items
   where user_id = p_user_id
     and variant_id in (select (e->>'variant_id')::uuid from jsonb_array_elements(p_items) e);
  return v_id;
end $$;

create or replace function public.settle_payment(
  p_txn_ref text, p_success boolean, p_txn_no text, p_bank text, p_code text, p_raw jsonb
) returns text
language plpgsql security definer set search_path = public as $$
declare v_order uuid;
begin
  update payments
     set status = (case when p_success then 'success' else 'failed' end)::payment_status,
         provider_txn_no = p_txn_no, bank_code = p_bank, response_code = p_code, raw = p_raw,
         paid_at = case when p_success then now() end
   where txn_ref = p_txn_ref and status = 'pending'
   returning order_id into v_order;
  if not found then return 'already'; end if;
  if p_success then
    update orders set status = 'paid' where id = v_order and status = 'pending_payment';
  end if;
  return 'ok';
end $$;

create or replace function public.expire_pending_orders() returns int
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  with c as (
    update orders set status = 'cancelled'
     where status = 'pending_payment' and expires_at < now()
    returning id
  ), s as (
    select oi.variant_id, sum(oi.quantity)::int as q, c.id as order_id
      from order_items oi join c on c.id = oi.order_id
     group by oi.variant_id, c.id
  ), u as (
    update product_variants pv set stock = pv.stock + s.q
      from s where pv.id = s.variant_id
    returning 1
  ), m as (
    insert into inventory_movements (variant_id, change, reason, order_id, note)
    select s.variant_id, s.q, 'order_cancelled', s.order_id, 'Don VNPay het han tu dong hoan kho'
    from s
    returning 1
  )
  select count(*) into n from c;
  return n;
end $$;

create or replace function public.adjust_stock(
  p_variant_id uuid, p_delta int, p_reason inventory_movement_reason,
  p_note text default null, p_admin_id uuid default null
) returns int
language plpgsql security definer set search_path = public as $$
declare v_new int;
begin
  if p_reason not in ('admin_restock', 'admin_correction') then
    raise exception 'INVALID_REASON:%', p_reason;
  end if;
  update product_variants set stock = stock + p_delta
   where id = p_variant_id and stock + p_delta >= 0
   returning stock into v_new;
  if not found then
    raise exception 'INVALID_ADJUSTMENT:variant=% delta=%', p_variant_id, p_delta;
  end if;
  insert into inventory_movements (variant_id, change, reason, created_by, note)
  values (p_variant_id, p_delta, p_reason, p_admin_id, p_note);
  return v_new;
end $$;

create or replace function public.admin_update_order_status(
  p_order_id uuid, p_new_status order_status, p_note text default null, p_admin_id uuid default null
) returns void
language plpgsql security definer set search_path = public as $$
declare v_old order_status;
begin
  if p_admin_id is not null and not exists (
    select 1 from profiles where id = p_admin_id and role = 'admin'
  ) then
    raise exception 'FORBIDDEN';
  end if;

  select status into v_old from orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND:%', p_order_id; end if;

  if not (
    (v_old = 'pending_payment' and p_new_status = 'cancelled') or
    (v_old = 'paid'            and p_new_status in ('processing', 'cancelled')) or
    (v_old = 'processing'      and p_new_status in ('shipping', 'cancelled')) or
    (v_old = 'shipping'        and p_new_status in ('completed', 'cancelled'))
  ) then
    raise exception 'INVALID_TRANSITION:% -> %', v_old, p_new_status;
  end if;

  if p_new_status = 'cancelled' then
    insert into inventory_movements (variant_id, change, reason, order_id, created_by, note)
    select oi.variant_id, oi.quantity, 'order_cancelled', p_order_id, p_admin_id, coalesce(p_note, 'huy boi admin')
      from order_items oi where oi.order_id = p_order_id;
    update product_variants pv set stock = pv.stock + oi.quantity
      from order_items oi where oi.variant_id = pv.id and oi.order_id = p_order_id;
  end if;

  update orders set status = p_new_status where id = p_order_id;
  insert into order_status_history (order_id, from_status, to_status, changed_by, note)
  values (p_order_id, v_old, p_new_status, p_admin_id, p_note);
end $$;

create or replace function public.track_order_by_code_phone(p_code text, p_phone text)
returns table (
  id uuid, code text, status order_status, total int,
  payment_method text, created_at timestamptz, items jsonb
)
language sql security definer set search_path = public as $$
  select o.id, o.code, o.status, o.total, o.payment_method, o.created_at,
    (select jsonb_agg(jsonb_build_object(
       'productName', oi.product_name, 'size', oi.size, 'color', oi.color,
       'quantity', oi.quantity, 'unitPrice', oi.unit_price
     )) from order_items oi where oi.order_id = o.id)
  from orders o
  where o.code = p_code and o.ship_phone = p_phone;
$$;

-- Grant permissions for RPC
revoke all on function public.create_order(uuid, jsonb, jsonb, text, int, text) from public, anon, authenticated;
revoke all on function public.settle_payment(text, boolean, text, text, text, jsonb) from public, anon, authenticated;
revoke all on function public.expire_pending_orders() from public, anon, authenticated;
revoke all on function public.adjust_stock(uuid, int, inventory_movement_reason, text, uuid) from public, anon, authenticated;
revoke all on function public.admin_update_order_status(uuid, order_status, text, uuid) from public, anon, authenticated;
revoke all on function public.track_order_by_code_phone(text, text) from public, authenticated;

grant execute on function public.create_order(uuid, jsonb, jsonb, text, int, text) to service_role;
grant execute on function public.settle_payment(text, boolean, text, text, text, jsonb) to service_role;
grant execute on function public.expire_pending_orders() to service_role;
grant execute on function public.adjust_stock(uuid, int, inventory_movement_reason, text, uuid) to service_role;
grant execute on function public.admin_update_order_status(uuid, order_status, text, uuid) to service_role;
grant execute on function public.track_order_by_code_phone(text, text) to anon, service_role;

-- 7. RLS POLICIES
alter table profiles         enable row level security;
alter table categories       enable row level security;
alter table products         enable row level security;
alter table product_variants enable row level security;
alter table product_images   enable row level security;
alter table cart_items       enable row level security;
alter table orders           enable row level security;
alter table order_items      enable row level security;
alter table payments         enable row level security;

-- Public / Customer reads
drop policy if exists "catalog read" on categories;
create policy "catalog read" on categories for select to anon, authenticated using (true);

drop policy if exists "catalog read" on products;
create policy "catalog read" on products for select to anon, authenticated using (is_active);

drop policy if exists "catalog read" on product_variants;
create policy "catalog read" on product_variants for select to anon, authenticated using (true);

drop policy if exists "catalog read" on product_images;
create policy "catalog read" on product_images for select to anon, authenticated using (true);

drop policy if exists "own profile read" on profiles;
create policy "own profile read" on profiles for select to authenticated using (id = (select auth.uid()));

-- Admin writes & reads
drop policy if exists "admin write categories" on categories;
create policy "admin write categories" on categories for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin write products" on products;
create policy "admin write products" on products for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin write product_variants" on product_variants;
create policy "admin write product_variants" on product_variants for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin write product_images" on product_images;
create policy "admin write product_images" on product_images for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin read profiles" on profiles;
create policy "admin read profiles" on profiles for select to authenticated using (public.is_admin());

drop policy if exists "admin read cart_items" on cart_items;
create policy "admin read cart_items" on cart_items for select to authenticated using (public.is_admin());

drop policy if exists "admin read orders" on orders;
create policy "admin read orders" on orders for select to authenticated using (public.is_admin());

drop policy if exists "admin read order_items" on order_items;
create policy "admin read order_items" on order_items for select to authenticated using (public.is_admin());

drop policy if exists "admin read payments" on payments;
create policy "admin read payments" on payments for select to authenticated using (public.is_admin());

-- 8. GRANT PRIVILEGES TO ROLES (Sua loi 42501 permission denied)
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on all tables in schema public to postgres, anon, authenticated, service_role;
grant all on all sequences in schema public to postgres, anon, authenticated, service_role;
grant all on all routines in schema public to postgres, anon, authenticated, service_role;

alter default privileges in schema public grant all on tables to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on routines to postgres, anon, authenticated, service_role;

-- 9. SEED DEFAULT ADMIN ACCOUNT (admin@gmail.com / 123456)
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

-- ==============================================================================
-- BẢNG: REVIEWS (ĐÁNH GIÁ SẢN PHẨM)
-- ==============================================================================

create table if not exists public.reviews (
    id uuid default gen_random_uuid() primary key,
    user_id uuid not null references public.profiles(id) on delete cascade,
    product_id uuid not null references public.products(id) on delete cascade,
    rating smallint not null check (rating >= 1 and rating <= 5),
    comment text,
    created_at timestamptz not null default now(),
    unique(user_id, product_id)
);

create index if not exists idx_reviews_product_id on public.reviews(product_id);
create index if not exists idx_reviews_user_id on public.reviews(user_id);

alter table public.reviews enable row level security;

drop policy if exists "reviews are viewable by everyone" on public.reviews;
create policy "reviews are viewable by everyone" on public.reviews
    for select using (true);

drop policy if exists "users can insert their own reviews" on public.reviews;
create policy "users can insert their own reviews" on public.reviews
    for insert with check (auth.uid() = user_id);

drop policy if exists "users can update their own reviews" on public.reviews;
create policy "users can update their own reviews" on public.reviews
    for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "users can delete their own reviews" on public.reviews;
create policy "users can delete their own reviews" on public.reviews
    for delete using (auth.uid() = user_id);

drop policy if exists "admins can delete any review" on public.reviews;
create policy "admins can delete any review" on public.reviews
    for delete using (
        coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false)
        or exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

grant all on table public.reviews to anon, authenticated, service_role;

create or replace view public.users as 
    select * from public.profiles;

grant all on public.users to anon, authenticated, service_role;

create or replace function public.update_reviews_product_rating()
returns trigger language plpgsql security definer as $$
declare
    v_prod_id uuid;
begin
    v_prod_id := case when tg_op = 'DELETE' then old.product_id else new.product_id end;
    update public.products
    set rating_avg = round((select coalesce(avg(rating), 0) from public.reviews where product_id = v_prod_id), 2),
        rating_count = (select count(*) from public.reviews where product_id = v_prod_id)
    where id = v_prod_id;
    return null;
end;
$$;

drop trigger if exists on_review_change on public.reviews;
create trigger on_review_change
after insert or update or delete on public.reviews
for each row execute function public.update_reviews_product_rating();

