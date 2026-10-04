import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/add_to_cart_button.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';

/// Horizontal (row) product tile. Shares the soft card language with
/// [ProductCard]: gentle border, soft shadow, rounded image and a secondary
/// price, with a press feedback via [Pressable].
class ProductListCard extends StatelessWidget {
  final Product product;
  const ProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isFav = context.watch<WishlistProvider>().isFavorite(product.id);

    return Pressable(
      onTap: () => context.push('/products/${product.id}'),
      scale: 0.98,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: SizedBox(width: 80, height: 80, child: _image(c)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatVnd(product.price),
                    style: TextStyle(
                      color: c.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AddToCartButton(
                    height: 34,
                    onTap: () {
                      if (!AuthGuard.check(context,
                          redirectPath: '/products')) {
                        return;
                      }
                      if (product.variants.isEmpty) {
                        context.push('/products/${product.id}');
                        return;
                      }
                      context
                          .read<CartProvider>()
                          .addItem(product, product.variants.first, 1);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã thêm vào giỏ hàng'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FavButton(
              active: isFav,
              onTap: () {
                if (!AuthGuard.check(
                  context,
                  actionTitle: 'Đăng nhập để lưu yêu thích',
                  actionMessage:
                      'Vui lòng đăng nhập để lưu "${product.name}" vào danh sách yêu thích của bạn.',
                )) {
                  return;
                }
                context.read<WishlistProvider>().toggleWishlist(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(AppColors c) {
    Widget fallback() => Container(
      color: c.surfaceVariant,
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0] : '?',
          style: TextStyle(
            color: c.secondary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    if (product.imageUrl.isEmpty) return fallback();
    return CachedNetworkImage(
      imageUrl: product.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: c.surfaceVariant),
      errorWidget: (_, _, _) => fallback(),
    );
  }
}

/// Soft circular favourite toggle with an animated heart swap.
class _FavButton extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  const _FavButton({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(active),
            size: 20,
            color: active ? c.danger : c.textMuted,
          ),
        ),
      ),
    );
  }
}
