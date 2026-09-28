import 'dart:io';

class ApiConfig {
  // ============================================================
  // ⚙️  CẤU HÌNH IP BACKEND
  //
  // Mỗi người clone về cần chỉnh IP này thành IP máy chạy backend:
  //   macOS/Linux : ifconfig | grep "inet " | grep -v 127
  //   Windows     : ipconfig → tìm dòng "IPv4 Address"
  //
  // iOS Simulator KHÔNG dùng được 'localhost' → phải dùng IP LAN.
  // Android Emulator tự động dùng '10.0.2.2'.
  // ============================================================

  /// ✏️ THAY GIÁ TRỊ NÀY = IP máy đang chạy backend của bạn
  static const String _localIp = '192.168.42.45';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000'; // Android emulator → localhost của host
    }
    return 'http://$_localIp:5000';  // iOS Simulator / thiết bị thật
  }

  static String get apiBase => '$baseUrl/api/v1';
}
