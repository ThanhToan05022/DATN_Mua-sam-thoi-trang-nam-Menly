import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      _snack('Vui lòng nhập đầy đủ mật khẩu hiện tại và mật khẩu mới');
      return;
    }
    if (_newCtrl.text.length < 6) {
      _snack('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _snack('Xác nhận mật khẩu không khớp');
      return;
    }
    if (_newCtrl.text == _currentCtrl.text) {
      _snack('Mật khẩu mới phải khác mật khẩu hiện tại');
      return;
    }

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        _snack('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại');
        context.push('/login');
        return;
      }

      final res = await http
          .post(
            Uri.parse('${ApiConfig.apiBase}/profile/change-password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'newPassword': _newCtrl.text,
              'currentPassword': _currentCtrl.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công, vui lòng đăng nhập lại'),
            backgroundColor: AppTheme.success,
          ),
        );
        // Xoa phien cuc bo de bat buoc dang nhap lai bang mat khau moi
        await prefs.remove('accessToken');
        await prefs.remove('userName');
        await prefs.remove('userEmail');
        if (mounted) context.go('/login');
      } else if (res.statusCode == 401) {
        _snack('Phiên đăng nhập không hợp lệ, vui lòng đăng nhập lại');
        await prefs.remove('accessToken');
        if (mounted) context.go('/login');
      } else {
        var message = 'Đổi mật khẩu thất bại';
        try {
          final body = jsonDecode(res.body);
          message = body['error']?['message'] ?? message;
        } catch (_) {
          // Phan hoi khong phai JSON - giu thong bao chung
        }
        _snack(message);
      }
    } catch (e) {
      if (mounted) _snack('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mật khẩu mới phải có ít nhất 6 ký tự. Sau khi đổi xong bạn sẽ được yêu cầu đăng nhập lại.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 28),
            _field(_currentCtrl, 'Mật khẩu hiện tại', Icons.lock_outline_rounded),
            const SizedBox(height: 14),
            _field(_newCtrl, 'Mật khẩu mới', Icons.lock_rounded),
            const SizedBox(height: 14),
            _field(_confirmCtrl, 'Xác nhận mật khẩu mới', Icons.lock_reset_rounded),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Xác nhận đổi mật khẩu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) => TextField(
        controller: ctrl,
        obscureText: _obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18, color: AppTheme.textMuted),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      );
}
