import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.border2, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
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
                  color: AppTheme.border2,
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
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.2),
                      AppTheme.primaryDark.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_person_rounded,
                    color: AppTheme.primary,
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
              style: const TextStyle(
                color: Colors.white,
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
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Nút Đăng nhập ngay (Primary CTA)
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                if (redirectPath != null && redirectPath!.isNotEmpty) {
                  context.push('/login?redirect=${Uri.encodeComponent(redirectPath!)}');
                } else {
                  context.push('/login');
                }
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Đăng nhập ngay',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nút Tạo tài khoản (Secondary CTA)
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (redirectPath != null && redirectPath!.isNotEmpty) {
                  context.push('/register?redirect=${Uri.encodeComponent(redirectPath!)}');
                } else {
                  context.push('/register');
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.border2, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tạo tài khoản mới',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // Nút Tiếp tục xem sản phẩm (Tertiary)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tiếp tục duyệt sản phẩm',
                style: TextStyle(
                  color: AppTheme.textMuted,
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
