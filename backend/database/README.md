# Cấu Trúc Cơ Sở Dữ Liệu MenShop / Menly (Supabase PostgreSQL)

Thư mục này chứa toàn bộ các câu lệnh SQL khởi tạo và vận hành cơ sở dữ liệu cho dự án **MenShop / Menly**, được tách rời độc lập và phân loại chi tiết theo từng chức năng nghiệp vụ.

---

## 1. Sơ Đồ Cấu Trúc Thư Mục

```text
database/
├── 01_types/                  # Tiện ích mở rộng và kiểu dữ liệu liệt kê (Enums)
│   ├── 01_extensions.sql      # Kích hoạt extension pg_trgm (fuzzy search)
│   └── 02_enums.sql           # order_status, payment_status, inventory_movement_reason
│
├── 02_tables/                 # Khởi tạo các bảng dữ liệu thực thể (25 bảng)
│   ├── 01_profiles.sql        # Hồ sơ người dùng, phân quyền (customer, admin, user, seller), cờ khóa
│   ├── 02_categories.sql      # Danh mục sản phẩm thời trang nam (Áo sơ mi, Polo, Quần, Áo khoác)
│   ├── 03_shops.sql           # Gian hàng người bán (Seller Marketplace), logo, rating
│   ├── 04_products.sql        # Sản phẩm: tên, giá, mô tả, kiểm duyệt, rating, chuỗi tìm kiếm
│   ├── 05_product_variants.sql# Biến thể sản phẩm: Size (M, L, XL), Màu sắc, Mã SKU, Tồn kho
│   ├── 06_product_images.sql  # Thư viện nhiều hình ảnh chi tiết của sản phẩm
│   ├── 07_cart_items.sql      # Giỏ hàng người dùng
│   ├── 08_orders.sql          # Đơn hàng: mã đơn, tổng tiền, phương thức COD/VNPay, shop_id
│   ├── 09_order_items.sql     # Chi tiết snapshot sản phẩm, đơn giá, kích cỡ tại lúc đặt
│   ├── 10_payments.sql        # Giao dịch cổng thanh toán VNPay (txn_ref, IPN response)
│   ├── 11_inventory_movements.sql # Nhật ký biến động tồn kho (nhập, xuất, hủy đơn hoàn kho)
│   ├── 12_order_status_history.sql # Lịch sử thời gian chuyển trạng thái đơn hàng
│   ├── 13_admin_audit_log.sql # Nhật ký kiểm toán hành vi của quản trị viên
│   ├── 14_user_addresses.sql  # Sổ địa chỉ nhận hàng của khách (Tỉnh, Huyện, Xã)
│   ├── 15_vouchers.sql        # Mã giảm giá toàn sàn (Admin) và mã riêng của Shop
│   ├── 16_order_vouchers.sql  # Liên kết mã giảm giá đã áp dụng vào đơn hàng
│   ├── 17_product_reviews.sql # Đánh giá sao (1-5), nhận xét và phản hồi của shop
│   ├── 18_order_returns.sql   # Yêu cầu trả hàng & hoàn tiền (Disputes & Returns)
│   ├── 19_wishlists.sql       # Danh sách sản phẩm yêu thích của khách hàng
│   ├── 20_shop_followers.sql  # Người dùng theo dõi gian hàng
│   ├── 21_chat_conversations.sql # Phòng chat giữa người mua và shop
│   ├── 22_chat_messages.sql   # Tin nhắn văn bản / hình ảnh realtime
│   ├── 23_notifications.sql   # Thông báo đẩy (đơn hàng, khuyến mãi, hệ thống)
│   ├── 24_banners.sql         # Banner quảng cáo slider trang chủ
│   └── 25_flash_sales.sql     # Khung giờ Flash Sale & sản phẩm giảm sốc
│
├── 03_indexes/                # Chỉ mục tối ưu hóa tốc độ truy vấn
│   ├── 01_product_indexes.sql # Index tìm kiếm tên (GIN trgm), lọc theo giá, danh mục, shop
│   ├── 02_order_indexes.sql   # Index lọc đơn theo ngày (Admin Dashboard), theo trạng thái, theo user
│   └── 03_marketplace_indexes.sql # Index cho thanh toán, kho, review, chat, voucher
│
├── 04_triggers/               # Trigger và hàm tự động kích hoạt
│   ├── 01_handle_new_user.sql # Tự động tạo hồ sơ profiles khi đăng ký qua auth.users
│   ├── 02_handle_user_anonymity_change.sql # Đồng bộ cờ is_guest khi chuyển từ khách ẩn danh
│   └── 03_update_product_and_shop_rating.sql # Tự động tính lại điểm sao cho sản phẩm & shop khi có review
│
├── 05_functions/              # Stored Procedures / RPC Functions
│   ├── 01_is_admin.sql        # Hàm kiểm tra quyền Admin & Staff từ Supabase JWT metadata
│   ├── 02_set_user_role.sql   # Phân quyền user/staff/admin đồng bộ auth.users & profiles
│   ├── 03_create_order.sql    # RPC đặt hàng ACID: khóa biến thể chống race condition, trừ kho
│   ├── 04_settle_payment.sql  # RPC cập nhật kết quả thanh toán VNPay IPN webhook
│   ├── 05_expire_pending_orders.sql # Cron tự động hủy đơn VNPay quá hạn 15p & hoàn kho
│   ├── 06_adjust_stock.sql    # RPC admin/staff điều chỉnh tồn kho (nhập hàng/kiểm kê)
│   ├── 07_admin_update_order_status.sql # RPC admin/staff chuyển trạng thái đơn hàng & hoàn kho nếu hủy
│   ├── 08_track_order_by_code_phone.sql # RPC tra cứu đơn công khai bằng Mã đơn + SĐT
│   └── 09_cancel_order_by_buyer.sql # RPC người mua tự hủy đơn khi chưa đóng gói & hoàn kho
│
├── 06_policies/               # Chính sách bảo mật hàng (Row Level Security - RLS)
│   ├── 01_enable_rls.sql      # Bật RLS cho toàn bộ các bảng trong hệ thống
│   ├── 02_catalog_policies.sql# Cho phép khách hàng xem danh mục, sản phẩm, hình ảnh, banner
│   ├── 03_user_profile_policies.sql # Khách hàng chỉ xem/sửa thông tin, đơn hàng của chính mình
│   └── 04_admin_policies.sql  # Admin toàn quyền hệ thống; Nhân viên (staff) toàn quyền vận hành
│
├── 07_permissions/            # Cấp quyền cho các vai trò Supabase
│   ├── 01_schema_permissions.sql # Cấp quyền schema public (sửa lỗi 42501 permission denied)
│   └── 02_rpc_permissions.sql # Phân quyền thực thi các hàm RPC cho anon, authenticated, service_role
│
├── 08_seeds/                  # Dữ liệu mẫu khởi tạo hệ thống
│   ├── 01_seed_admin.sql      # Tạo tài khoản admin mặc định: admin@gmail.com / 123456
│   ├── 01_seed_staff.sql      # Tạo tài khoản nhân viên mặc định: staff@gmail.com / 123456
│   ├── 02_seed_categories.sql # 5 danh mục thời trang nam chuẩn UUID
│   ├── 03_seed_products.sql   # 125 sản phẩm thời trang nam chia đều 5 danh mục
│   ├── 04_seed_variants.sql   # Biến thể kích cỡ M, L, XL, màu tiêu chuẩn, SKU và tồn kho thực
│   └── 05_seed_product_images.sql # Đồng bộ ảnh đại diện vào thư viện ảnh sản phẩm
│
└── apply_all.sql              # File tổng hợp toàn bộ 54 module theo đúng thứ tự phụ thuộc
```

---

## 2. Hướng Dẫn Thực Thi (Execution Guide)

### Cách 1: Chạy toàn bộ hệ thống bằng 1 file (Khuyên dùng)
Nếu bạn cài đặt database mới trên **Supabase Dashboard**:
1. Truy cập **Supabase Dashboard** -> Chọn Project của bạn.
2. Mở menu **SQL Editor** ở cột bên trái.
3. Mở file [apply_all.sql](file:///c:/Users/ThanhToan/DATN_Mua-sam-thoi-trang-nam-Menly/backend/database/apply_all.sql) -> Copy toàn bộ nội dung và dán vào SQL Editor.
4. Bấm nút **Run** (hoặc `Ctrl + Enter`).

### Cách 2: Chạy thủ công từng module theo thứ tự phụ thuộc
Nếu muốn chạy từng file hoặc kiểm tra từng tính năng, hãy tuân thủ thứ tự sau:
1. **01_types**: Chạy `01_extensions.sql` -> `02_enums.sql`
2. **02_tables**: Chạy tuần tự từ `01_profiles.sql` đến `25_flash_sales.sql`
3. **03_indexes**: Chạy các file index để tăng tốc truy vấn
4. **04_triggers**: Chạy các hàm trigger
5. **05_functions**: Chạy các hàm Stored Procedure / RPC
6. **06_policies**: Kích hoạt RLS và thiết lập chính sách bảo mật
7. **07_permissions**: Cấp quyền schema và hàm RPC
8. **08_seeds**: Nạp dữ liệu tài khoản admin, danh mục và 125 sản phẩm mẫu
