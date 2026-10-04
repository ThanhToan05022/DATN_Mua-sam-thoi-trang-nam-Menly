import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../data/models/product_model.dart';

class CategoryFilterBar extends StatelessWidget {
  final ScrollController scrollController;
  final List<Category> categories;
  final String selectedCatId;
  final ValueChanged<String> onSelectCategory;

  const CategoryFilterBar({
    super.key,
    required this.scrollController,
    required this.categories,
    required this.selectedCatId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final isAll = i == 0;
          final id = isAll ? 'all' : categories[i - 1].id;
          final label = isAll ? 'Tất cả' : categories[i - 1].name;
          final isSelected = isAll
              ? selectedCatId == 'all'
              : (selectedCatId.toLowerCase() == id.toLowerCase() ||
                    selectedCatId.toLowerCase() ==
                        categories[i - 1].slug.toLowerCase() ||
                    selectedCatId.toLowerCase() ==
                        categories[i - 1].name.toLowerCase());

          return Pressable(
            onTap: () => onSelectCategory(id),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected ? c.primary : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : c.border.withValues(alpha: 0.6),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? c.onPrimary : c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
