import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AuthGuard {
  /// Kiểm tra xem người dùng đã đăng nhập chưa.
  /// - Nếu đã đăng nhập: Trả về `true` và có thể gọi `onAuthenticated`.
  /// - Nếu ẩn danh (chưa đăng nhập): Chặn hành động, hiển thị Modal Taste Skill yêu cầu đăng nhập, trả về `false`.
  static bool check(
    BuildContext context, {
    String actionTitle = 'Yêu cầu đăng nhập',
    String actionMessage =
        'Bạn đang ở chế độ xem ẩn danh. Để thêm vào giỏ hàng hoặc tiến hành mua hàng, vui lòng đăng nhập tài khoản Menly.',
    String? redirectPath,
    VoidCallback? onAuthenticated,
  }) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      onAuthenticated?.call();
      return true;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black87,
      builder: (ctx) => _LoginPromptSheet(
        title: actionTitle,
        message: actionMessage,
        redirectPath: redirectPath,
      ),
    );

    return false;
  }
}

class _LoginPromptSheet extends StatelessWidget {
  final String title;
  final String message;
  final String? redirectPath;

  const _LoginPromptSheet({
    required this.title,
    required this.message,
    this.redirectPath,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: c.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 36,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh kéo handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon Badge cao cấp (Taste-Skill styled)
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.secondary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_person_rounded,
                    color: c.secondary,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Lời giải thích rõ ràng, súc tích (Anti-slop copywriting)
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Nút Đăng nhập ngay (Primary CTA)
            PrimaryButton(
              label: 'Đăng nhập ngay',
              onPressed: () {
                Navigator.of(context).pop();
                if (redirectPath != null && redirectPath!.isNotEmpty) {
                  context.push('/login?redirect=${Uri.encodeComponent(redirectPath!)}');
                } else {
                  context.push('/login');
                }
              },
            ),
            const SizedBox(height: 12),

            // Nút Tạo tài khoản (Secondary CTA)
            SecondaryButton(
              label: 'Tạo tài khoản mới',
              onPressed: () {
                Navigator.of(context).pop();
                if (redirectPath != null && redirectPath!.isNotEmpty) {
                  context.push('/register?redirect=${Uri.encodeComponent(redirectPath!)}');
                } else {
                  context.push('/register');
                }
              },
            ),
            const SizedBox(height: 8),

            // Nút Tiếp tục xem sản phẩm (Tertiary)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tiếp tục duyệt sản phẩm',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
