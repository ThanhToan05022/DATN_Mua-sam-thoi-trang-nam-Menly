import 'package:flutter/material.dart';

import '../../../../core/widgets/state_views.dart';

class ProductEmptyView extends StatelessWidget {
  final VoidCallback onClearFilters;
  const ProductEmptyView({super.key, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return StatusView(
      icon: Icons.search_off_rounded,
      title: 'Không tìm thấy sản phẩm',
      message: 'Thử bỏ bớt bộ lọc hoặc tìm với từ khoá khác.',
      actionLabel: 'Xoá bộ lọc',
      onAction: onClearFilters,
    );
  }
}

class ProductErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ProductErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StatusView(
      icon: Icons.error_outline_rounded,
      title: 'Đã xảy ra lỗi',
      message: error,
      actionLabel: 'Thử lại',
      onAction: onRetry,
      danger: true,
    );
  }
}
