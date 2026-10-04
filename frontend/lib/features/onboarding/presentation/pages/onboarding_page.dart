import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';

/// First-run onboarding screen, styled after the reference design:
/// a photo collage, a bold headline and the primary "Get Started" CTA.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _heroImages = [
    'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?w=600',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600',
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Collage(images: _heroImages, colors: c)),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: c.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Dễ dàng tiếp cận\n',
                      style: TextStyle(
                        color: c.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const TextSpan(text: 'thời trang nam cao cấp'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Khám phá bộ sưu tập chọn lọc, đặt hàng nhanh gọn và '
                'nhận hàng tận nơi — mua sắm chưa bao giờ dễ đến thế.',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const _Dots(count: 3, active: 0),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Bắt đầu ngay',
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Text.rich(
                    TextSpan(
                      text: 'Đã có tài khoản? ',
                      style: TextStyle(color: c.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Đăng nhập',
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Collage extends StatelessWidget {
  final List<String> images;
  final AppColors colors;
  const _Collage({required this.images, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: _tile(images[0], 190, 150, 'Chất lượng'),
        ),
        Align(
          alignment: Alignment.topRight,
          child: _tile(images[1], 130, 150, 'Phong cách'),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _tile(images[2], 200, 170, 'Giao nhanh'),
        ),
      ],
    );
  }

  Widget _tile(String url, double w, double h, String tag) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: CachedNetworkImage(
              imageUrl: url,
              width: w,
              height: h,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: w, height: h, color: colors.surfaceVariant),
              errorWidget: (_, __, ___) =>
                  Container(width: w, height: h, color: colors.surfaceVariant),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.inkCard.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: colors.onInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? c.secondary : c.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
