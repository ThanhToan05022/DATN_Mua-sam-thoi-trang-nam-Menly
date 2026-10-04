import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'add_to_cart_button.dart';
import 'pressable.dart';
import '../../features/product/data/models/product_model.dart';

/// Product tile used in grids and horizontal rails. Fills the width given by
/// its parent, so wrap it in a `SizedBox(width: ...)` for horizontal lists.
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAdd;
  final String? badge; // e.g. a real promo label when available

  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite = false,
    this.onTap,
    this.onToggleFavorite,
    this.onAdd,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: _image(c),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.inkCard.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: c.onInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FavButton(
                    active: isFavorite,
                    onTap: onToggleFavorite,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatVnd(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AddToCartButton(onTap: onAdd ?? onTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(AppColors c) {
    if (product.imageUrl.isEmpty) {
      return Container(
        color: c.surfaceVariant,
        child: Icon(Icons.image_outlined, color: c.textMuted, size: 36),
      );
    }
    return CachedNetworkImage(
      imageUrl: product.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: c.surfaceVariant),
      errorWidget: (_, __, ___) => Container(
        color: c.surfaceVariant,
        child: Icon(Icons.broken_image_outlined, color: c.textMuted, size: 32),
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(active),
            size: 18,
            color: active ? c.danger : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
