-- ==============================================================================
-- TRIGGER & FUNCTION: UPDATE_PRODUCT_AND_SHOP_RATING
-- Tự động tính điểm uy tín trung bình (rating_avg, rating_count) cho Sản phẩm & Gian hàng
-- khi người dùng gửi đánh giá sản phẩm mới
-- ==============================================================================

create or replace function public.update_product_and_shop_rating()
returns trigger language plpgsql security definer as $$
declare
  v_shop_id uuid;
begin
  -- 1. Cập nhật rating sản phẩm
  update public.products
  set rating_avg = round((select coalesce(avg(rating), 0) from public.product_reviews where product_id = new.product_id), 2),
      rating_count = (select count(*) from public.product_reviews where product_id = new.product_id)
  where id = new.product_id
  returning shop_id into v_shop_id;

  -- 2. Cập nhật rating của shop (nếu sản phẩm thuộc shop)
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
