-- ==============================================================================
-- BẢNG: REVIEWS (ĐÁNH GIÁ SẢN PHẨM)
-- Tương thích hệ thống Supabase của Menly Shop (liên kết với public.profiles)
-- ==============================================================================

-- 1. Tạo view public.users trỏ tới public.profiles để tương thích ngược nếu cần
CREATE OR REPLACE VIEW public.users AS 
    SELECT * FROM public.profiles;

GRANT ALL ON public.users TO anon, authenticated, service_role;

-- 2. Tạo bảng reviews (liên kết với public.profiles và public.products)
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, product_id)
);

-- Index để tối ưu truy vấn theo sản phẩm và người dùng
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);

-- 3. Bật Row Level Security (RLS)
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 4. Chính sách RLS cho bảng reviews (idempotent với DROP POLICY IF EXISTS)
DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON public.reviews;
CREATE POLICY "Reviews are viewable by everyone" ON public.reviews
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own reviews" ON public.reviews;
CREATE POLICY "Users can insert their own reviews" ON public.reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own reviews" ON public.reviews;
CREATE POLICY "Users can update their own reviews" ON public.reviews
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own reviews" ON public.reviews;
CREATE POLICY "Users can delete their own reviews" ON public.reviews
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can delete any review" ON public.reviews;
CREATE POLICY "Admins can delete any review" ON public.reviews
    FOR DELETE USING (
        coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false)
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 5. Cấp quyền truy cập bảng cho các role Supabase
GRANT ALL ON TABLE public.reviews TO anon, authenticated, service_role;
