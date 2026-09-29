import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('savedEmail') ?? '';
    if (!mounted) return;
    if (saved.isNotEmpty) {
      setState(() {
        _emailCtrl.text = saved;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('Vui lòng nhập email và mật khẩu');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.apiBase}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailCtrl.text.trim(),
              'password': _passCtrl.text,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        // Ghi nhớ email nếu bật Remember Me
        if (_rememberMe) {
          await prefs.setString('savedEmail', _emailCtrl.text.trim());
        } else {
          await prefs.remove('savedEmail');
        }
        await prefs.setString('accessToken', body['accessToken'] ?? '');
        await prefs.setString('userName', body['user']?['name'] ?? '');
        await prefs.setString('userEmail', body['user']?['email'] ?? '');
        if (mounted) context.go('/');
      } else {
        _snack(body['error']?['message'] ?? 'Đăng nhập thất bại');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('MENLY', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
              ),
              const Center(
                child: Text('Thời trang nam cao cấp', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 48),
              const Text('Đăng nhập', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Chào mừng bạn trở lại!', style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
              const SizedBox(height: 28),

              // Email
              _label('Email'),
              const SizedBox(height: 8),
              _inputField(
                controller: _emailCtrl,
                hint: 'example@email.com',
                icon: Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              _label('Mật khẩu'),
              const SizedBox(height: 8),
              _inputField(
                controller: _passCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.textMuted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 16),

              // Remember me + Quên mật khẩu
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: _rememberMe ? AppTheme.primary : Colors.transparent,
                            border: Border.all(
                              color: _rememberMe ? AppTheme.primary : AppTheme.textMuted,
                              width: 1.8,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _rememberMe
                              ? const Icon(Icons.check_rounded, color: Colors.black, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Ghi nhớ đăng nhập',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng quên mật khẩu đang được phát triển'),
                        backgroundColor: AppTheme.surface2,
                      ),
                    ),
                    child: const Text('Quên mật khẩu?',
                        style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Login button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: AppTheme.surface2)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('hoặc', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
                Expanded(child: Divider(color: AppTheme.surface2)),
              ]),
              const SizedBox(height: 20),

              // Go to register
              OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Tạo tài khoản mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 24),

              // Continue as guest
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Tiếp tục không đăng nhập →', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
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
