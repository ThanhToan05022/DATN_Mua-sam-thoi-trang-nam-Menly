import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const ProductSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
