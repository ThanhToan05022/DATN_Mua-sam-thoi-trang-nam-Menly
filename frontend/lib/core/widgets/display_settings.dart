import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_accent.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Circular "display" button that opens the appearance settings sheet.
class DisplaySettingsButton extends StatelessWidget {
  final double size;
  const DisplaySettingsButton({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = context.watch<ThemeController>().isDark;
    return Material(
      color: c.surface,
      shape: CircleBorder(side: BorderSide(color: c.border, width: 1.2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showDisplaySettings(context),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: size * 0.46,
            color: c.primary,
          ),
        ),
      ),
    );
  }
}

Future<void> showDisplaySettings(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _DisplaySettingsSheet(),
  );
}

class _DisplaySettingsSheet extends StatelessWidget {
  const _DisplaySettingsSheet();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final controller = context.watch<ThemeController>();

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 14, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hiển thị',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tùy chỉnh giao diện theo ý bạn',
            style: TextStyle(color: c.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: 22),

          // Light / Dark toggle
          Text('Chế độ', style: _labelStyle(c)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ModeChip(
                label: 'Sáng',
                icon: Icons.light_mode_rounded,
                selected: controller.mode == ThemeMode.light,
                onTap: () => controller.setMode(ThemeMode.light),
              ),
              const SizedBox(width: 12),
              _ModeChip(
                label: 'Tối',
                icon: Icons.dark_mode_rounded,
                selected: controller.mode == ThemeMode.dark,
                onTap: () => controller.setMode(ThemeMode.dark),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Accent color picker
          Text('Màu chủ đạo', style: _labelStyle(c)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final accent in AppAccent.values)
                _AccentDot(
                  accent: accent,
                  selected: controller.accent == accent,
                  onTap: () => controller.setAccent(accent),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  TextStyle _labelStyle(AppColors c) => TextStyle(
        color: c.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: selected ? c.primarySoft : c.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? c.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 19, color: selected ? c.primary : c.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? c.primary : c.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? c.textPrimary : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            accent.label,
            style: TextStyle(color: c.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
