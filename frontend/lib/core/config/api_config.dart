import 'dart:io';

class ApiConfig {
  // iOS Simulator không dùng được localhost → dùng IP máy Mac
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    // iOS Simulator & macOS → IP LAN của máy Mac
    return 'http://192.168.42.45:5000';
  }

  static String get apiBase => '$baseUrl/api/v1';
}
