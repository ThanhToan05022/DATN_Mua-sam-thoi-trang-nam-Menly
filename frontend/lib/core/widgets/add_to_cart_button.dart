import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// The single, app-wide "add to cart" affordance: a soft tonal button with a
/// cart icon and label. Used on every product card so the action looks the
/// same everywhere.
class AddToCartButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final double height;

  const AddToCartButton({
    super.key,
    required this.onTap,
    this.label = 'Thêm giỏ',
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 17, color: c.textPrimary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
