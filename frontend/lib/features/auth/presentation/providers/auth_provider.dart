import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/view_state.dart';

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'admin' | 'staff' | 'customer' | 'guest'
  final String? phone;
  final String? address;
  final String? avatarUrl;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.address,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isStaffOrAdmin => role == 'admin' || role == 'staff';

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] ?? '',
        email: j['email'] ?? '',
        fullName: j['fullName'] ?? j['full_name'] ?? j['name'] ?? '',
        role: j['role'] ?? 'customer',
        phone: j['phone'],
        address: j['address'],
        avatarUrl: j['avatarUrl'] ?? j['avatar_url'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'phone': phone,
        'address': address,
        'avatarUrl': avatarUrl,
      };

  AuthUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? phone,
    String? address,
    String? avatarUrl,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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

        final phone = prefs.getString('user_phone');
        final address = prefs.getString('user_address');
        final avatar = prefs.getString('user_avatar');

        final authUser = AuthUser(
          id: u.id,
          email: u.email ?? '',
          fullName: name,
          role: role,
          phone: phone,
          address: address,
          avatarUrl: avatar,
        );

        _state = ViewState.success(authUser);
        notifyListeners();
        fetchProfile();
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
      final address = prefs.getString('user_address');
      final avatar = prefs.getString('user_avatar');

      if (token != null && token.isNotEmpty && email != null) {
        final authUser = AuthUser(
          id: id,
          email: email,
          fullName: name ?? email.split('@').first,
          role: role,
          phone: phone,
          address: address,
          avatarUrl: avatar,
        );
        _state = ViewState.success(authUser);
        fetchProfile();
      } else {
        _state = ViewState.initial();
      }
    } catch (_) {
      _state = ViewState.initial();
    } finally {
      notifyListeners();
    }
  }

  /// Tải thông tin hồ sơ người dùng mới nhất từ server
  Future<void> fetchProfile() async {
    try {
      final res = await _dioClient.dio.get('/profile');
      if (res.statusCode == 200 && res.data != null) {
        final body = res.data is Map ? res.data['data'] : null;
        if (body is Map<String, dynamic> && user != null) {
          final updated = user!.copyWith(
            fullName: body['full_name'] ?? user!.fullName,
            phone: body['phone'] ?? user!.phone,
            address: body['address'] ?? user!.address,
            avatarUrl: body['avatar_url'] ?? user!.avatarUrl,
          );
          _state = ViewState.success(updated);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', updated.fullName);
          if (updated.phone != null) await prefs.setString('user_phone', updated.phone!);
          if (updated.address != null) await prefs.setString('user_address', updated.address!);

          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Cập nhật thông tin cá nhân (Họ tên, SĐT, Địa chỉ)
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phone,
    String? address,
  }) async {
    try {
      final res = await _dioClient.dio.put('/profile', data: {
        'fullName': fullName.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (address != null) 'address': address.trim(),
      });

      if (res.statusCode == 200) {
        final resData = res.data is Map ? res.data['data'] : null;
        final newPhone = resData != null && resData['phone'] != null ? resData['phone'].toString() : phone;
        final newAddress = resData != null && resData['address'] != null ? resData['address'].toString() : address;
        final newAvatar = resData != null && resData['avatar_url'] != null ? resData['avatar_url'].toString() : null;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', fullName.trim());
        if (newPhone != null) await prefs.setString('user_phone', newPhone.trim());
        if (newAddress != null) await prefs.setString('user_address', newAddress.trim());
        if (newAvatar != null) await prefs.setString('user_avatar', newAvatar.trim());

        if (user != null) {
          final updated = user!.copyWith(
            fullName: fullName.trim(),
            phone: newPhone?.trim() ?? user!.phone,
            address: newAddress?.trim() ?? user!.address,
            avatarUrl: newAvatar?.trim() ?? user!.avatarUrl,
          );
          _state = ViewState.success(updated);
          notifyListeners();
        }
        return {'success': true, 'message': 'Cập nhật thông tin thành công'};
      }
      return {'success': false, 'message': 'Cập nhật thất bại'};
    } catch (e) {
      String msg = 'Có lỗi xảy ra khi cập nhật';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          final err = data['error'];
          msg = (err is Map ? err['message'] : err).toString();
        }
      }
      return {'success': false, 'message': msg};
    }
  }

  /// Upload hình ảnh thay đổi Avatar
  Future<Map<String, dynamic>> uploadAvatar(Uint8List imageBytes, {String mimeType = 'image/jpeg'}) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final res = await _dioClient.dio.post('/profile/upload-avatar', data: {
        'imageBase64': base64Image,
        'contentType': mimeType,
      });

      if (res.statusCode == 200 && res.data != null) {
        final avatarUrl = (res.data['avatarUrl'] ?? (res.data['data'] != null ? res.data['data']['avatar_url'] : null))?.toString();
        if (avatarUrl != null && user != null) {
          final updated = user!.copyWith(avatarUrl: avatarUrl);
          _state = ViewState.success(updated);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_avatar', avatarUrl);
          notifyListeners();
        }
        return {'success': true, 'avatarUrl': avatarUrl, 'message': 'Cập nhật ảnh đại diện thành công'};
      }
      return {'success': false, 'message': 'Upload ảnh thất bại'};
    } catch (e) {
      String msg = 'Có lỗi xảy ra khi tải ảnh lên';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          final err = data['error'];
          msg = (err is Map ? err['message'] : err).toString();
        }
      }
      return {'success': false, 'message': msg};
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
    await prefs.remove('user_avatar');
    await prefs.remove('user_phone');
    await prefs.remove('user_address');

    _state = ViewState.initial();
    notifyListeners();
  }
}
