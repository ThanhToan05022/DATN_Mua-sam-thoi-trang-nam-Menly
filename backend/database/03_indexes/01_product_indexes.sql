-- ==============================================================================
-- INDEXES: SẢN PHẨM & BIẾN THỂ (TỐI ƯU TRUY VẤN VÀ TÌM KIẾM)
-- Tối ưu hóa phân trang theo ngày, theo giá, theo danh mục, shop và tìm kiếm tiếng Việt
-- ==============================================================================

-- 1. Tối ưu sắp xếp sản phẩm mới nhất
create index if not exists products_newest_idx on public.products (created_at desc, id desc) where is_active;

-- 2. Tối ưu lọc và sắp xếp theo giá
create index if not exists products_price_idx on public.products (price, id) where is_active;

-- 3. Tối ưu lọc theo danh mục
create index if not exists products_category_idx on public.products (category_id, created_at desc, id desc) where is_active;

-- 4. Tìm kiếm Full-text/Fuzzy search bằng pg_trgm
create index if not exists products_search_trgm on public.products using gin (search_text extensions.gin_trgm_ops);

-- 5. Liên kết khóa ngoại giữa biến thể và sản phẩm
create index if not exists variants_product_idx on public.product_variants (product_id);

-- 6. Tối ưu lấy sản phẩm theo gian hàng (shop)
create index if not exists products_shop_idx on public.products (shop_id, created_at desc);
