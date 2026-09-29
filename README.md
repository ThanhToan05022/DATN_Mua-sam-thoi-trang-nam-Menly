# 🛍️ Menly — Ứng dụng Mua sắm Thời trang Nam

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Node.js-Express-green?logo=nodedotjs" />
  <img src="https://img.shields.io/badge/Next.js-Admin-black?logo=nextdotjs" />
  <img src="https://img.shields.io/badge/Supabase-Postgres-brightgreen?logo=supabase" />
</p>

> **Đồ án tốt nghiệp** — Ứng dụng thương mại điện tử thời trang nam trên nền tảng di động (iOS/Android) với giao diện premium dark theme.

---

## 📁 Cấu trúc dự án

```
DATN_Mua-sam-thoi-trang-nam-Menly/
├── frontend/        # Flutter app (iOS & Android)
├── backend/         # Node.js + Express REST API
└── admin/           # Next.js Admin Dashboard
```

---

## ✨ Tính năng chính

### 📱 Mobile App (Flutter)
- Màn hình khởi động (splash) có animation
- Trang chủ: banner, danh mục sản phẩm, sản phẩm nổi bật, kéo để tải lại
- Danh sách sản phẩm: lọc theo danh mục, tìm kiếm theo tên, chuyển đổi chế độ lưới/danh sách
- Chi tiết sản phẩm: chọn size/màu, chọn số lượng, thêm vào giỏ
- Giỏ hàng: tăng/giảm số lượng, xoá bằng swipe
- Đặt hàng: thông tin giao hàng, chọn COD hoặc VNPay
- Đăng ký / Đăng nhập / Ghi nhớ đăng nhập / Đăng nhập khách
- Đổi mật khẩu
- Trang hồ sơ & đăng xuất
- **Bảo vệ:** yêu cầu đăng nhập mới được thanh toán

### ⚙️ Backend (Node.js + Express)
- REST API theo Clean Architecture (domain → application → infrastructure → presentation)
- Xác thực bằng Supabase JWT (middleware `requireAuth` / `requireAdmin` / `requireCustomer`)
- Validate toàn bộ input bằng Zod
- Phân trang cursor, bộ lọc và sắp xếp danh sách sản phẩm
- Quản lý tồn kho theo biến thể (size, màu) + lịch sử biến động kho
- Audit log cho thao tác quản trị
- Bảo mật: Helmet, CORS, rate limiting theo route, log redact token
- Tích hợp thanh toán VNPay (sandbox) + webhook IPN có xác thực chữ ký HMAC

### 🖥️ Admin Dashboard (Next.js)
- Đăng nhập quản trị (chỉ tài khoản role `admin`)
- Bảng điều khiển: doanh thu, tỉ lệ xử lý đơn, cơ cấu sản phẩm theo danh mục, lọc theo ngày
- Quản lý sản phẩm: xem danh sách, đổi danh mục, xem chi tiết tồn kho theo size
- Quản lý đơn hàng: lọc theo trạng thái, cập nhật trạng thái kèm ghi chú
- Quản lý kho: nhập thêm / hiệu chỉnh tồn kho, xem lịch sử biến động
- Quản lý người dùng: tìm kiếm, lọc theo vai trò, khóa/mở khóa, đổi vai trò
- Nhật ký hệ thống (audit log)
- Trang giám sát hệ thống & cấu hình kết nối

---

## 📌 Phạm vi hiện tại

Một số chức năng trong tài liệu thiết kế **chưa được triển khai** và không có trong bản phát hành này:
lịch sử đơn hàng, sổ địa chỉ, yêu thích, đánh giá sản phẩm, voucher, banner động,
thông báo, quên mật khẩu, quản lý cửa hàng người bán, trò chuyện.

---

## 🚀 Hướng dẫn cài đặt & chạy

### Yêu cầu
| Công cụ | Phiên bản |
|---------|-----------|
| Flutter | 3.x |
| Node.js | 18+ |
| npm | 9+ |
| Supabase | Tài khoản miễn phí (Postgres + Auth + Storage) — *không bắt buộc nếu chạy chế độ dữ liệu giả lập* |

---

### 1️⃣ Clone dự án

```bash
git clone https://github.com/ThanhToan05022/DATN_Mua-sam-thoi-trang-nam-Menly.git
cd DATN_Mua-sam-thoi-trang-nam-Menly
```

---

### 2️⃣ Cài đặt Backend

```bash
cd backend
cp .env.example .env     # Sao chép file cấu hình
```

Mở file `.env`. Có 2 chế độ chạy:

**a) Chạy nhanh với dữ liệu giả lập (không cần tài khoản Supabase)**
```env
USE_MOCK_DB=true
```

**b) Chạy với Supabase thật**
```env
USE_MOCK_DB=false
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```
Lấy các giá trị này tại **Supabase Dashboard → Project Settings → API**.
Sau đó nạp schema và dữ liệu mẫu bằng các file trong `backend/database/`
(`complete_setup.sql`, `marketplace_v2_migration.sql`, `seed.sql`).

> ⚠️ File `.env` chứa thông tin nhạy cảm đã được thêm vào `.gitignore` — không commit file này.

```bash
npm install
npm run seed     # nạp dữ liệu mẫu (tùy chọn)
npm run dev      # Backend chạy tại http://localhost:5000
npm test         # chạy 38 unit + integration test
```

**Tài khoản quản trị mặc định** (do `seed.sql` tạo): `admin@gmail.com` / `123456`

---

### 3️⃣ Cài đặt Admin Dashboard

```bash
cd admin
npm install
npm run dev       # Admin chạy tại http://localhost:3000
```

> Admin gọi API trực tiếp từ trình duyệt về `http://localhost:5000`.
> Nếu backend chạy ở địa chỉ khác, mở trang **Cài đặt** trong admin để sửa.
> Khi backend không phản hồi, admin sẽ **hiển thị lỗi thật** chứ không dùng dữ liệu giả.

---

### 4️⃣ Cài đặt Flutter App

```bash
cd frontend
flutter pub get
```

#### ⚠️ QUAN TRỌNG — Cấu hình IP Backend

iOS Simulator **không dùng được `localhost`** — phải dùng IP LAN của máy chạy backend.

**Bước 1:** Tìm IP máy của bạn:
```bash
# macOS / Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows (CMD)
ipconfig
# → tìm dòng "IPv4 Address"
```

**Bước 2:** Mở file `frontend/lib/core/config/api_config.dart` và đổi IP:
```dart
/// ✏️ THAY GIÁ TRỊ NÀY = IP máy đang chạy backend của bạn
static const String _localIp = '192.168.x.x';   // ← đổi thành IP của bạn
```

**Bước 3:** Thêm cùng IP đó vào 2 file cấu hình bảo mật, nếu không app sẽ bị chặn kết nối HTTP:
- `frontend/android/app/src/main/res/xml/network_security_config.xml` → thêm `<domain>` tương ứng
- `frontend/ios/Runner/Info.plist` → thêm entry trong `NSAppTransportSecurity > NSExceptionDomains`

**Bước 4:** Chạy app:
```bash
# Xem danh sách thiết bị/simulator
flutter devices

# Chạy trên simulator/emulator
flutter run -d <device-id>

# Hoặc chạy trên thiết bị thật (đảm bảo cùng mạng WiFi với backend)
flutter run
```

---

## 📱 Các nhánh Git

| Nhánh | Mô tả |
|-------|-------|
| `main` | Nhánh chính, ổn định |
| `feat/mobile-ui-redesign` | UI/UX mới — premium dark theme |
| `feat/splash-screen-and-ui-fixes` | Màn hình splash & sửa lỗi UI trang chủ |
| `feat/profile-upload-password` | Tính năng đổi avatar & mật khẩu |

---

## 🔧 Troubleshooting

### App không kết nối được backend
- ✅ Đảm bảo backend đang chạy (`npm run dev`)
- ✅ Đổi đúng IP trong `api_config.dart`
- ✅ Máy điện thoại/simulator và máy chạy backend **phải cùng mạng WiFi**
- ✅ Tắt VPN nếu đang bật

### iOS Simulator lỗi "Connection refused"
```bash
# Tìm IP đúng
ifconfig en0 | grep "inet "
# → Dùng địa chỉ "inet xxx.xxx.xxx.xxx" đó trong api_config.dart
```

### Android Emulator
Android Emulator dùng `10.0.2.2` thay cho `localhost` — **đã được cấu hình sẵn**, không cần đổi.

### flutter pub get lỗi
```bash
flutter clean
flutter pub get
```

### Đặt hàng báo lỗi 401
Backend chặn khách chưa đăng nhập đặt hàng. Hãy đăng nhập trong app trước khi thanh toán.

### Bản build release không gọi được API
- ✅ Kiểm tra `INTERNET` permission có trong `android/app/src/main/AndroidManifest.xml`
- ✅ Kiểm tra `network_security_config.xml` có liệt kê đúng host/IP backend
- ✅ Trên iOS: kiểm tra `NSAppTransportSecurity` trong `Info.plist`

---

## 🧪 Kiểm thử

```bash
# Backend — 38 test (unit + integration)
cd backend && npm test

# Admin — kiểm tra kiểu và lint
cd admin && npx tsc --noEmit && npm run lint

# Mobile — kiểm tra phân tích tĩnh
cd frontend && flutter analyze && flutter test
```

---

## 👥 Nhóm thực hiện

> Đồ án tốt nghiệp — Khoa Công nghệ Thông tin

---

## 📄 License

MIT License — Chỉ dùng cho mục đích học tập.
