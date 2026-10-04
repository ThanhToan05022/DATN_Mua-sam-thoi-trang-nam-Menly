import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ProductSortType {
  defaultSort('default', 'Mặc định', Icons.tune_rounded),
  priceAsc('price_asc', 'Giá: Thấp đến Cao', Icons.trending_up_rounded),
  priceDesc('price_desc', 'Giá: Cao đến Thấp', Icons.trending_down_rounded),
  newest('newest', 'Mới nhất', Icons.flash_on_rounded);

  final String value;
  final String label;
  final IconData icon;

  const ProductSortType(this.value, this.label, this.icon);
}

class ProductSortBar extends StatelessWidget {
  final int totalCount;
  final String currentSort;
  final ValueChanged<String> onSortChanged;

  const ProductSortBar({
    super.key,
    required this.totalCount,
    required this.currentSort,
    required this.onSortChanged,
  });

  String _getSortLabel() {
    for (final opt in ProductSortType.values) {
      if (opt.value == currentSort) return opt.label;
    }
    return 'Mặc định';
  }

  void _showSortBottomSheet(BuildContext context) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).padding.bottom + 104),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    color: c.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sắp xếp sản phẩm',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: c.textMuted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: c.border, height: 1),
              const SizedBox(height: 8),
              ...ProductSortType.values.map((opt) {
                final isSelected = opt.value == currentSort;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(ctx);
                      onSortChanged(opt.value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.secondary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? c.secondary.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            opt.icon,
                            size: 20,
                            color: isSelected ? c.secondary : c.textMuted,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                color: isSelected
                                    ? c.textPrimary
                                    : c.textSecondary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: c.secondary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isPriceAsc = currentSort == ProductSortType.priceAsc.value;
    final isPriceDesc = currentSort == ProductSortType.priceDesc.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          // Số lượng sản phẩm
          Text(
            '$totalCount sản phẩm',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),

          // Nút bấm nhanh: Giá tăng dần (Thấp -> Cao)
          _QuickSortChip(
            label: 'Giá ↑',
            tooltip: 'Giá: Thấp đến Cao',
            isSelected: isPriceAsc,
            onTap: () {
              if (isPriceAsc) {
                onSortChanged(ProductSortType.defaultSort.value);
              } else {
                onSortChanged(ProductSortType.priceAsc.value);
              }
            },
          ),
          const SizedBox(width: 8),

          // Nút bấm nhanh: Giá giảm dần (Cao -> Thấp)
          _QuickSortChip(
            label: 'Giá ↓',
            tooltip: 'Giá: Cao đến Thấp',
            isSelected: isPriceDesc,
            onTap: () {
              if (isPriceDesc) {
                onSortChanged(ProductSortType.defaultSort.value);
              } else {
                onSortChanged(ProductSortType.priceDesc.value);
              }
            },
          ),
          const SizedBox(width: 8),

          // Nút mở modal sắp xếp đầy đủ
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showSortBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (currentSort != ProductSortType.defaultSort.value)
                      ? c.secondary.withValues(alpha: 0.5)
                      : c.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: (currentSort != ProductSortType.defaultSort.value)
                        ? c.secondary
                        : c.textMuted,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 85),
                    child: Text(
                      _getSortLabel(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (currentSort != ProductSortType.defaultSort.value)
                            ? c.secondary
                            : c.textMuted,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: c.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSortChip extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSortChip({
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? c.secondary.withValues(alpha: 0.18)
                : c.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? c.secondary : c.border,
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? c.secondary : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
