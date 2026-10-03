import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  final String? redirect;
  const RegisterPage({super.key, this.redirect});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _selectedRole = 'customer'; // 'customer' | 'staff'
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

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name,
      email,
      pass,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRole == 'staff'
                ? '🎉 Đăng ký tài khoản Nhân viên thành công!'
                : '🎉 Đăng ký tài khoản Khách hàng thành công!',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      context.read<WishlistProvider>().fetchWishlist(forceRefresh: true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        final target = widget.redirect ??
            GoRouterState.of(context).uri.queryParameters['redirect'];
        if (target != null && target.isNotEmpty) {
          context.go(target);
        } else {
          context.go('/');
        }
      }
    } else {
      _snack(auth.state.message ?? 'Đăng ký thất bại. Vui lòng thử lại.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Back
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Tạo tài khoản',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Đăng ký để mua sắm hoặc quản lý vận hành Menly',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
              const SizedBox(height: 24),

              // Vai trò tài khoản (Khách hàng vs Nhân viên)
              _label('Loại tài khoản'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'customer'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'customer'
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: _selectedRole == 'customer'
                                      ? Colors.black
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Khách hàng',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedRole == 'customer'
                                        ? Colors.black
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'staff'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'staff'
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  size: 16,
                                  color: _selectedRole == 'staff'
                                      ? Colors.black
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Nhân viên',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedRole == 'staff'
                                        ? Colors.black
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Name
              _label('Họ và tên'),
              const SizedBox(height: 8),
              _inputField(
                  controller: _nameCtrl,
                  hint: 'Nguyễn Văn A',
                  icon: Icons.person_outline_rounded),
              const SizedBox(height: 16),

              // Email
              _label('Email'),
              const SizedBox(height: 8),
              _inputField(
                  controller: _emailCtrl,
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress),
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
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppTheme.textMuted,
                      size: 20),
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
                  icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppTheme.textMuted,
                      size: 20),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 28),

              // Register button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _selectedRole == 'staff'
                              ? 'Đăng ký Nhân viên'
                              : 'Đăng ký Khách hàng',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Go to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? ',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Đăng nhập',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary));

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
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
