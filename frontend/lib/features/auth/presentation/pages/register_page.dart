import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _snack('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (pass.length < 6) {
      _snack('Mật khẩu phải ít nhất 6 ký tự');
      return;
    }
    if (pass != confirm) {
      _snack('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.apiBase}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': pass}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', body['accessToken'] ?? '');
        await prefs.setString('userName', body['user']?['name'] ?? name);
        await prefs.setString('userEmail', body['user']?['email'] ?? email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Đăng ký thành công!'), backgroundColor: AppTheme.success),
          );
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.go('/');
        }
      } else {
        _snack(body['error']?['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      _snack('Lỗi kết nối: $e');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Back
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () { if (context.canPop()) context.pop(); else context.go('/login'); },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Tạo tài khoản', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Đăng ký để mua sắm dễ dàng hơn', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
              const SizedBox(height: 32),

              // Name
              _label('Họ và tên'),
              const SizedBox(height: 8),
              _inputField(controller: _nameCtrl, hint: 'Nguyễn Văn A', icon: Icons.person_outline_rounded),
              const SizedBox(height: 16),

              // Email
              _label('Email'),
              const SizedBox(height: 8),
              _inputField(controller: _emailCtrl, hint: 'example@email.com', icon: Icons.email_outlined, type: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Password
              _label('Mật khẩu'),
              const SizedBox(height: 8),
              _inputField(
                controller: _passCtrl,
                hint: 'Ít nhất 6 ký tự',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.textMuted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm password
              _label('Xác nhận mật khẩu'),
              const SizedBox(height: 8),
              _inputField(
                controller: _confirmPassCtrl,
                hint: 'Nhập lại mật khẩu',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.textMuted, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 32),

              // Register button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),

              // Go to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? ', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Đăng nhập', style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surface2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
