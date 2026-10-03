# 🛍️ Menly — Ứng dụng Mua sắm Thời trang Nam

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Node.js-Express-green?logo=nodedotjs" />
  <img src="https://img.shields.io/badge/Next.js-Admin-black?logo=nextdotjs" />
  <img src="https://img.shields.io/badge/Supabase-Database-brightgreen?logo=supabase" />
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

- Trang chủ với banner và danh mục sản phẩm
- Danh sách sản phẩm: tìm kiếm, lọc theo danh mục, chế độ grid/list
- Chi tiết sản phẩm: chọn size/màu, xem ảnh
- Giỏ hàng: thêm/xoá/cập nhật số lượng (swipe to delete)
- Thanh toán & đặt hàng
- Đăng ký / Đăng nhập / Remember Me
- Trang hồ sơ cá nhân & lịch sử đơn hàng
- **Bảo vệ:** Yêu cầu đăng nhập mới được thêm giỏ & thanh toán

### ⚙️ Backend (Node.js)

- REST API đầy đủ: sản phẩm, danh mục, đơn hàng, người dùng
- Xác thực JWT (access token + refresh token)
- Upload ảnh sản phẩm
- Quản lý tồn kho theo biến thể (size, màu)

### 🖥️ Admin Dashboard (Next.js)

- Quản lý sản phẩm, danh mục, đơn hàng, người dùng
- Thống kê doanh thu

---

## 🚀 Hướng dẫn cài đặt & chạy

### Yêu cầu

| Công cụ | Phiên bản |
| ------- | --------- |
| Flutter | 3.x       |
| Node.js | 18+       |
| MongoDB | 6+        |
| npm     | 9+        |

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

Mở file `.env` và điền thông tin:

```bash
npm install
npm run dev       # Backend chạy tại http://localhost:5000
```

---

### 3️⃣ Cài đặt Admin Dashboard

```bash
cd admin
npm install
npm run dev       # Admin chạy tại http://localhost:3000
```

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

**Bước 3:** Chạy app:

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

| Nhánh                          | Mô tả                             |
| ------------------------------ | --------------------------------- |
| `main`                         | Nhánh chính, ổn định              |
| `feat/mobile-ui-redesign`      | ✨ UI/UX mới — premium dark theme |
| `feat/profile-upload-password` | Tính năng đổi avatar & mật khẩu   |

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

---

## 👥 Nhóm thực hiện

> Đồ án tốt nghiệp — Khoa Công nghệ Thông tin

---

## 📄 License

MIT License — Chỉ dùng cho mục đích học tập.
