import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

class PillNavItem {
  final IconData icon;
  final int badge;
  const PillNavItem(this.icon, {this.badge = 0});
}

/// Floating pill-shaped bottom navigation bar matching the reference design.
class AppPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PillNavItem> items;

  const AppPillNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < items.length; i++)
              _NavButton(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final icon = Icon(
      item.icon,
      size: 24,
      color: selected ? c.primary : c.onPrimary,
    );

    return Pressable(
      onTap: onTap,
      scale: 0.9,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? c.surface : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: item.badge > 0
              ? Badge(
                  label: Text('${item.badge}'),
                  backgroundColor: c.secondary,
                  textColor: c.inkCard,
                  child: icon,
                )
              : icon,
        ),
      ),
    );
  }
}
