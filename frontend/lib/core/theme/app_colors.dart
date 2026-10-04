import 'package:flutter/material.dart';
import 'app_accent.dart';

/// Semantic color tokens for the Menly design system.
///
/// Exposed as a [ThemeExtension] so widgets read `AppColors.of(context)` and
/// automatically get the right values for the current brightness + accent.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color onPrimary;
  final Color primarySoft; // tinted background for primary elements
  final Color secondary; // yellow pop accent
  final Color background;
  final Color surface; // cards
  final Color surfaceVariant; // chips, search field, subtle fills
  final Color inkCard; // dark promo card ("Up To 50%")
  final Color onInk;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color danger;
  final Color shadow;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.inkCard,
    required this.onInk,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.danger,
    required this.shadow,
  });

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        AppColors.light(AppAccent.camel);
  }

  /// "Kem & Ink" boutique light scheme: cream canvas, near-black ink for CTAs
  /// and the pill nav, with the chosen accent used as a warm highlight.
  factory AppColors.light(AppAccent accent) {
    return AppColors(
      primary: const Color(0xFF1C1B17), // ink — CTA, nav, selected
      onPrimary: const Color(0xFFF7F5F1),
      primarySoft: accent.color.withValues(alpha: 0.14),
      secondary: accent.color, // camel highlight
      background: const Color(0xFFF7F5F1), // cream
      surface: const Color(0xFFFFFFFF),
      surfaceVariant: const Color(0xFFEFEBE3), // beige fills
      inkCard: const Color(0xFF1C1B17),
      onInk: const Color(0xFFF7F5F1),
      textPrimary: const Color(0xFF15140F),
      textSecondary: const Color(0xFF6E6A5F),
      textMuted: const Color(0xFFA7A294),
      border: const Color(0xFFE8E2D7),
      success: const Color(0xFF3E7C5A),
      danger: const Color(0xFFC0564B),
      shadow: const Color(0x14000000),
    );
  }

  /// Warm dark counterpart: near-black canvas, the accent drives CTAs and nav
  /// so they stay visible against the dark surfaces.
  factory AppColors.dark(AppAccent accent) {
    return AppColors(
      primary: accent.color, // accent — CTA, nav on dark
      onPrimary: const Color(0xFF17140F),
      primarySoft: accent.color.withValues(alpha: 0.20),
      secondary: accent.color,
      background: const Color(0xFF141210),
      surface: const Color(0xFF1E1B17),
      surfaceVariant: const Color(0xFF272320),
      inkCard: const Color(0xFF0D0B09),
      onInk: const Color(0xFFF3EFE7),
      textPrimary: const Color(0xFFF3EFE7),
      textSecondary: const Color(0xFFB4ADA0),
      textMuted: const Color(0xFF7D766A),
      border: const Color(0xFF2E2A25),
      success: const Color(0xFF5CBF8E),
      danger: const Color(0xFFD9796E),
      shadow: const Color(0x66000000),
    );
  }

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? inkCard,
    Color? onInk,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? danger,
    Color? shadow,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      inkCard: inkCard ?? this.inkCard,
      onInk: onInk ?? this.onInk,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      inkCard: Color.lerp(inkCard, other.inkCard, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
