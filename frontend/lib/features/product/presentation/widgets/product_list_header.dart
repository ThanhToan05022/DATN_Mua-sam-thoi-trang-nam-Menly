import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class ProductListHeader extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onToggleView;

  const ProductListHeader({
    super.key,
    required this.isGridView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (context.canPop()) ...[
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],
          const Text(
            'Sản phẩm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          ProductIconButton(
            icon: isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            onTap: onToggleView,
          ),
        ],
      ),
    );
  }
}

class ProductIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const ProductIconButton({
    super.key,
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child:
              Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 20),
        ),
      );
}
