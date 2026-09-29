-- ==============================================================================
-- 01. EXTENSIONS
-- MenShop / Menly Supabase
-- Kích hoạt extension pg_trgm phục vụ tìm kiếm gần đúng (fuzzy search) cho sản phẩm
-- ==============================================================================

create extension if not exists pg_trgm with schema extensions;
