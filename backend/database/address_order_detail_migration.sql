-- ==============================================================================
-- MIGRATION: DIA CHI GIAO HANG + CHI TIET DON HANG
--
-- 1) Bo sung cot con thieu cho bang `orders` (ma da ton tai nhung thieu cot).
--    Code backend da ghi/doc cac cot nay nen can co trong DB.
-- 2) Bo sung index cho truy van danh sach dia chi theo user + mac dinh.
-- 3) Bo sung index cho doc lich su trang thai don (timeline chi tiet don).
-- 4) Bo sung cot `note` cho don + trigger ghi moc lich su khi TAO don.
--    Doi trang thai do OrderModel ghi truc tiep vao `order_status_history`
--    (de kem `note` va `from_status` chinh xac), nen KHONG tao trigger UPDATE
--    o day de tranh ghi trung dong lich su.
--
-- Chay an toan nhieu lan (idempotent). File apply_all.sql khong can sua.
-- ==============================================================================

-- 1. Cot bo sung cho `orders` ------------------------------------------------
alter table public.orders add column if not exists note text;
alter table public.orders add column if not exists voucher_code text;
alter table public.orders add column if not exists discount_amount int not null default 0;

-- 2. Index cho `user_addresses` ---------------------------------------------
create index if not exists user_addresses_user_idx
  on public.user_addresses (user_id, is_default desc, created_at desc);

-- 3. Index cho `order_status_history` ---------------------------------------
create index if not exists order_status_history_order_idx
  on public.order_status_history (order_id, created_at asc, id asc);

-- 4. Backfill: don cu chua co lich su trang thai thi ghi moc dau tien ---------
insert into public.order_status_history (order_id, from_status, to_status, note)
select o.id, null, o.status, 'Don hang duoc tao'
from public.orders o
where not exists (
  select 1 from public.order_status_history h where h.order_id = o.id
);

-- 5. Trigger ghi lich su khi TAO don -----------------------------------------
-- Chi xu ly INSERT. Cac lan doi trang thai do OrderModel ghi truc tiep.
-- --------------------------------------------------------------------------
create or replace function public.log_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.order_status_history (order_id, from_status, to_status, note)
  values (new.id, null, new.status, 'Don hang duoc tao');
  return new;
end;
$$;

drop trigger if exists "order_status_history_log" on public.orders;
create trigger "order_status_history_log"
  after insert on public.orders
  for each row execute function public.log_order_status_change();