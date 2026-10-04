import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
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
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

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
        final c = AppColors.of(context);
        context.read<CartProvider>().fetchCart();
        context.read<WishlistProvider>().fetchWishlist(forceRefresh: true);
        context.read<OrderProvider>().fetchMyOrders(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Chào mừng trở lại, ${auth.user?.fullName ?? ''}!',
            ),
            backgroundColor: c.success,
            duration: const Duration(seconds: 2),
          ),
        );
        final target =
            widget.redirect ??
            GoRouterState.of(context).uri.queryParameters['redirect'];
        if (target != null && target.isNotEmpty) {
          context.go(target);
        } else {
          context.go('/');
        }
      }
    } else {
      _snack(
        auth.state.message ??
            'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.',
      );
    }
  }

  void _snack(String msg) {
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: c.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final authState = context.watch<AuthProvider>().state;
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: c.background,
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
                    color: c.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: c.onPrimary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'MENLY',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Thời trang nam cao cấp',
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chào mừng bạn trở lại!',
                style: TextStyle(fontSize: 14, color: c.textMuted),
              ),
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
                    color: c.textMuted,
                    size: 20,
                  ),
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
                            color: _rememberMe ? c.primary : Colors.transparent,
                            border: Border.all(
                              color: _rememberMe ? c.primary : c.textMuted,
                              width: 1.8,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: _rememberMe
                              ? Icon(
                                  Icons.check_rounded,
                                  color: c.onPrimary,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ghi nhớ đăng nhập',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng liên hệ quản trị viên để khôi phục mật khẩu',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Login button
              PrimaryButton(
                label: 'Đăng nhập',
                loading: isLoading,
                onPressed: isLoading ? null : _login,
              ),
              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: c.surfaceVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'hoặc',
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: c.surfaceVariant)),
                ],
              ),
              const SizedBox(height: 20),

              // Go to register
              SecondaryButton(
                label: 'Tạo tài khoản mới',
                onPressed: () {
                  final target =
                      widget.redirect ??
                      GoRouterState.of(context).uri.queryParameters['redirect'];
                  if (target != null && target.isNotEmpty) {
                    context.push(
                      '/register?redirect=${Uri.encodeComponent(target)}',
                    );
                  } else {
                    context.push('/register');
                  }
                },
              ),
              const SizedBox(height: 24),

              // Continue as guest
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  'Tiếp tục không đăng nhập →',
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    final c = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: c.textSecondary,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        style: TextStyle(color: c.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: c.textMuted, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
