import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ==============================================================================
  // ⚙️ CẤU HÌNH IP / URL BACKEND CHO TỪNG NỀN TẢNG (ANDROID & IOS)
  // ==============================================================================
  //
  // 💡 NGUYÊN TẮC KẾT NỐI MẠNG:
  // - Android Emulator : Chạy trên máy ảo QEMU riêng, dùng 'http://10.0.2.2:5000' để trỏ về máy tính.
  // - iOS Simulator     : Dùng chung card mạng với Mac, DÙNG THẲNG 'http://localhost:5000'
  //                       -> Người dùng iOS Simulator KHÔNG CẦN chỉnh sửa IP LAN nữa!
  // - Máy thật (Android/iOS) : Cần cùng mạng Wi-Fi và dùng IP LAN máy tính (vd: 192.168.1.x)
  //                            hoặc đường dẫn Cloud/Ngrok/Cloudflare tunnel.
  // ==============================================================================

  // 🤖 1. CẤU HÌNH DÀNH RIÊNG CHO ANDROID
  // Mặc định: Máy ảo Android Emulator dùng 10.0.2.2:5000
  // Nếu dùng máy thật: đổi thành IP LAN máy tính của bạn (vd: 'http://192.168.1.100:5000')
  // Hoặc truyền qua: flutter run --dart-define=API_URL_ANDROID=...
  static const String androidBaseUrl = String.fromEnvironment(
    'API_URL_ANDROID',
    defaultValue: 'http://10.0.2.2:5000',
  );

  // 🍎 2. CẤU HÌNH DÀNH RIÊNG CHO IOS
  // Mặc định: iOS Simulator dùng thẳng 'http://localhost:5000' (TỰ ĐỘNG KẾT NỐI MAC, KHÔNG CẦN SỬA IP)
  // Nếu dùng máy thật iPhone: đổi thành IP LAN máy tính của bạn (vd: 'http://192.168.1.100:5000')
  // Hoặc truyền qua: flutter run --dart-define=API_URL_IOS=...
  static const String iosBaseUrl = String.fromEnvironment(
    'API_URL_IOS',
    defaultValue: 'http://localhost:5000',
  );

  // 💻 3. CẤU HÌNH DÀNH CHO MÁY BÀN & WEB (macOS / Windows / Linux Desktop / Web)
  static const String desktopBaseUrl = 'http://localhost:5000';

  // 🌐 4. CẤU HÌNH GHI ĐÈ TOÀN CỤC (Tùy chọn - Dành cho Server Deploy / Tunnel Ngrok)
  // flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Tự động trả về Base URL thích hợp theo nền tảng đang chạy
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return desktopBaseUrl;
    }

    if (Platform.isAndroid) {
      return androidBaseUrl;
    }

    if (Platform.isIOS) {
      return iosBaseUrl;
    }

    return desktopBaseUrl;
  }

  static String get apiBase => '$baseUrl/api/v1';
}
