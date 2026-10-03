import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cart/data/cart_model.dart';
import '../../../order/presentation/providers/order_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  final String? redirect;
  const LoginPage({super.key, this.redirect});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
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

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('savedEmail', _emailCtrl.text.trim());
      } else {
        await prefs.remove('savedEmail');
      }

      // Tải lại danh sách yêu thích, đơn hàng và giỏ hàng cho người dùng vừa đăng nhập
      if (mounted) {
        context.read<CartProvider>().fetchCart();
        context.read<WishlistProvider>().fetchWishlist(forceRefresh: true);
        context.read<OrderProvider>().fetchMyOrders(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Chào mừng trở lại, ${auth.user?.fullName ?? ''}!'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
        final target = widget.redirect ??
            GoRouterState.of(context).uri.queryParameters['redirect'];
        if (target != null && target.isNotEmpty) {
          context.go(target);
        } else {
          context.go('/');
        }
      }
    } else {
      _snack(auth.state.message ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.');
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
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('MENLY',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3)),
              ),
              const Center(
                child: Text('Thời trang nam cao cấp',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 48),
              const Text('Đăng nhập',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Chào mừng bạn trở lại!',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
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

              // Remember me + Quên mật khẩu
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? AppTheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _rememberMe
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                              width: 1.8,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _rememberMe
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.black, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Ghi nhớ đăng nhập',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Vui lòng liên hệ quản trị viên để khôi phục mật khẩu'),
                        ),
                      );
                    },
                    child: const Text('Quên mật khẩu?',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Login button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
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
                      : const Text('Đăng nhập',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: AppTheme.surface2)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('hoặc',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 13))),
                Expanded(child: Divider(color: AppTheme.surface2)),
              ]),
              const SizedBox(height: 20),

              // Go to register
              OutlinedButton(
                onPressed: () {
                  final target = widget.redirect ??
                      GoRouterState.of(context).uri.queryParameters['redirect'];
                  if (target != null && target.isNotEmpty) {
                    context.push(
                        '/register?redirect=${Uri.encodeComponent(target)}');
                  } else {
                    context.push('/register');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Tạo tài khoản mới',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 24),

              // Continue as guest
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Tiếp tục không đăng nhập →',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
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
