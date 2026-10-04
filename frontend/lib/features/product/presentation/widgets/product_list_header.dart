import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_buttons.dart';

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
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          if (context.canPop()) ...[
            CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => context.pop(),
              size: 40,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Text(
            'Sản phẩm',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          CircleIconButton(
            icon: isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            onTap: onToggleView,
            size: 40,
          ),
        ],
      ),
    );
  }
}
