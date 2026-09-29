-- ==============================================================================
-- 01. BẬT ROW LEVEL SECURITY (RLS) CHO CÁC BẢNG TRONG HỆ THỐNG
-- Đảm bảo an toàn dữ liệu, ngăn chặn truy cập trái phép qua Supabase Client
-- ==============================================================================

alter table public.profiles          enable row level security;
alter table public.categories        enable row level security;
alter table public.products          enable row level security;
alter table public.product_variants  enable row level security;
alter table public.product_images    enable row level security;
alter table public.cart_items        enable row level security;
alter table public.orders            enable row level security;
alter table public.order_items       enable row level security;
alter table public.payments          enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.order_status_history enable row level security;
alter table public.admin_audit_log   enable row level security;

-- Marketplace tables
alter table public.shops             enable row level security;
alter table public.user_addresses    enable row level security;
alter table public.vouchers          enable row level security;
alter table public.order_vouchers    enable row level security;
alter table public.product_reviews   enable row level security;
alter table public.order_returns     enable row level security;
alter table public.wishlists         enable row level security;
alter table public.shop_followers    enable row level security;
alter table public.chat_conversations enable row level security;
alter table public.chat_messages     enable row level security;
alter table public.notifications     enable row level security;
alter table public.banners           enable row level security;
alter table public.flash_sales       enable row level security;
alter table public.flash_sale_items  enable row level security;
