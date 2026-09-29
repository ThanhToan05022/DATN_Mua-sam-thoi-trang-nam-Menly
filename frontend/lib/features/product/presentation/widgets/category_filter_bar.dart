import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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

          return GestureDetector(
            onTap: () => onSelectCategory(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppTheme.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
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
