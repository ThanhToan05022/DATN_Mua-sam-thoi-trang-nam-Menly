import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/view_state.dart';

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'admin' | 'staff' | 'customer' | 'guest'
  final String? avatarUrl;
  final String? phone;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.phone,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isStaffOrAdmin => role == 'admin' || role == 'staff';

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] ?? '',
        email: j['email'] ?? '',
        fullName: j['fullName'] ??
            j['full_name'] ??
            j['name'] ??
            j['user_metadata']?['full_name'] ??
            '',
        role: j['role'] ?? 'customer',
        avatarUrl: j['avatarUrl'] ?? j['avatar_url'],
        phone: j['phone']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'avatarUrl': avatarUrl,
        'phone': phone,
      };

  AuthUser copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return AuthUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final DioClient _dioClient;

  AuthProvider({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance {
    _initAuth();
  }

  ViewState<AuthUser> _state = ViewState.initial();
  ViewState<AuthUser> get state => _state;

  AuthUser? get user => _state.data;
  bool get isLoggedIn => user != null;

  Future<void> _initAuth() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      // 1. Kiểm tra session Supabase Auth trước (chỉ tính nếu là tài khoản thật, không phải ẩn danh)
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null &&
          session.user.isAnonymous != true &&
          session.user.email != null &&
          session.user.email!.isNotEmpty) {
        final u = session.user;
        final prefs = await SharedPreferences.getInstance();
        final storedRole = prefs.getString('user_role');

        String role = 'customer';
        final metaRole = u.appMetadata['role'] ?? u.userMetadata?['role'];
        if (metaRole != null && metaRole.toString().isNotEmpty) {
          role = metaRole.toString();
        } else if (storedRole != null && storedRole.isNotEmpty) {
          role = storedRole;
        } else if (u.email?.toLowerCase().contains('admin') == true) {
          role = 'admin';
        } else if (u.email?.toLowerCase().contains('staff') == true) {
          role = 'staff';
        }

        final name = u.userMetadata?['full_name'] ??
            prefs.getString('user_name') ??
            u.email?.split('@').first ??
            'Khách';

        final authUser = AuthUser(
          id: u.id,
          email: u.email ?? '',
          fullName: name,
          role: role,
        );

        _state = ViewState.success(authUser);
        notifyListeners();
        return;
      }

      // 2. Fallback sang SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ??
          prefs.getString('token') ??
          prefs.getString('accessToken');
      final email = prefs.getString('user_email');
      final name = prefs.getString('user_name');
      final role = prefs.getString('user_role') ?? 'customer';
      final id = prefs.getString('user_id') ?? '';
      final phone = prefs.getString('user_phone');
      final avatarUrl = prefs.getString('user_avatar_url');

      if (token != null && token.isNotEmpty && email != null) {
        final authUser = AuthUser(
          id: id,
          email: email,
          fullName: name ?? email.split('@').first,
          role: role,
          phone: phone,
          avatarUrl: avatarUrl,
        );
        _state = ViewState.success(authUser);
      } else {
        _state = ViewState.initial();
      }
    } catch (_) {
      _state = ViewState.initial();
    } finally {
      notifyListeners();
    }
  }

  /// Đăng nhập tài khoản (hỗ trợ Admin, Nhân viên và Khách hàng)
  Future<bool> login(String email, String password) async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      // Gọi API backend (có cơ chế khóa tài khoản lũy tiến và bảo vệ brute-force)
      final res = await _dioClient.dio.post('/auth/login', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      final body = res.data;
      final userData = body['user'] as Map<String, dynamic>? ?? {};
      final accessToken = body['accessToken'] ?? body['token'] ?? '';

      final authUser = AuthUser.fromJson(userData);

      // Lưu trữ phiên đăng nhập cục bộ
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('token', accessToken);
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('user_id', authUser.id);
      await prefs.setString('user_email', authUser.email);
      await prefs.setString('user_name', authUser.fullName);
      await prefs.setString('user_role', authUser.role);

      // Thử đồng bộ đăng nhập Supabase client nếu có
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
      } catch (_) {}

      _state = ViewState.success(authUser);
      notifyListeners();
      return true;
    } catch (e) {
      _state = ViewState.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký tài khoản mới (Khách hàng hoặc Nhân viên vận hành)
  Future<bool> register(
    String name,
    String email,
    String password, {
    String role = 'customer',
  }) async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      final res = await _dioClient.dio.post('/auth/register', data: {
        'fullName': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
      });

      final body = res.data;
      final userData = body['user'] as Map<String, dynamic>? ?? {};
      final accessToken = body['accessToken'] ?? body['token'] ?? '';

      final authUser = AuthUser.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      if (accessToken.isNotEmpty) {
        await prefs.setString('access_token', accessToken);
        await prefs.setString('token', accessToken);
        await prefs.setString('accessToken', accessToken);
      }
      await prefs.setString('user_id', authUser.id);
      await prefs.setString('user_email', authUser.email);
      await prefs.setString('user_name', authUser.fullName);
      await prefs.setString('user_role', authUser.role);

      _state = ViewState.success(authUser);
      notifyListeners();
      return true;
    } catch (e) {
      _state = ViewState.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Lấy hồ sơ đầy đủ (tên, SĐT, avatar) từ server
  Future<void> fetchProfile() async {
    try {
      final res = await _dioClient.dio.get('/profile');
      final body = res.data;
      final raw = body is Map && body['data'] is Map
          ? body['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      if (raw.isEmpty) return;

      final current = user;
      if (current == null) return;

      final updated = current.copyWith(
        fullName: (raw['full_name'] ?? raw['fullName'] ?? current.fullName)
            .toString(),
        phone: (raw['phone'] ?? current.phone)?.toString(),
        avatarUrl: (raw['avatar_url'] ?? raw['avatarUrl'])?.toString(),
      );

      _state = ViewState.success(updated);
      await _persistProfile(updated);
      notifyListeners();
    } catch (_) {
      // Giữ nguyên thông tin đang có nếu API lỗi
    }
  }

  /// Cập nhật tên và số điện thoại
  Future<bool> updateProfile({String? fullName, String? phone}) async {
    final current = user;
    if (current == null) return false;

    final payload = <String, dynamic>{
      if (fullName != null) 'fullName': fullName.trim(),
      if (phone != null) 'phone': phone.trim(),
    };
    if (payload.isEmpty) return true;

    try {
      await _dioClient.dio.put('/profile', data: payload);

      final updated = current.copyWith(
        fullName: fullName?.trim(),
        phone: phone?.trim(),
      );
      _state = ViewState.success(updated);
      await _persistProfile(updated);
      notifyListeners();
      return true;
    } catch (_) {
      // Vẫn lưu cục bộ để không mất thay đổi của người dùng
      final updated = current.copyWith(
        fullName: fullName?.trim(),
        phone: phone?.trim(),
      );
      _state = ViewState.success(updated);
      await _persistProfile(updated);
      notifyListeners();
      return false;
    }
  }

  /// Upload ảnh đại diện (base64) và cập nhật vào hồ sơ
  Future<bool> uploadAvatar(String base64Image) async {
    final current = user;
    if (current == null) return false;

    try {
      final res = await _dioClient.dio.post('/profile/upload-avatar', data: {
        'imageBase64': base64Image,
        'contentType': 'image/jpeg',
      });
      final body = res.data;
      final url = body is Map
          ? (body['avatarUrl'] ?? body['avatar_url'])?.toString()
          : null;
      if (url == null || url.isEmpty) return false;

      final updated = current.copyWith(avatarUrl: url);
      _state = ViewState.success(updated);
      await _persistProfile(updated);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistProfile(AuthUser updated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', updated.fullName);
    // Xoá key cũ khi server trả null để không bị đọc lại giá trị cũ.
    if (updated.phone != null && updated.phone!.isNotEmpty) {
      await prefs.setString('user_phone', updated.phone!);
    } else {
      await prefs.remove('user_phone');
    }
    if (updated.avatarUrl != null && updated.avatarUrl!.isNotEmpty) {
      await prefs.setString('user_avatar_url', updated.avatarUrl!);
    } else {
      await prefs.remove('user_avatar_url');
    }
  }

  /// Đăng xuất an toàn
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('token');
    await prefs.remove('accessToken');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('user_phone');
    await prefs.remove('user_avatar_url');

    _state = ViewState.initial();
    notifyListeners();
  }
}
