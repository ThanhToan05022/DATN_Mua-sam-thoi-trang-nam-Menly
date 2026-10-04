import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_accent.dart';
import 'app_colors.dart';

/// Central theme factory for the Menly design system.
///
/// Use [AppTheme.build] to generate a light/dark [ThemeData] for a chosen
/// accent. The legacy static color constants below are kept for screens that
/// have not been migrated to the new [AppColors] tokens yet.
class AppTheme {
  AppTheme._();

  // Shared corner-radius scale (design tokens).
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 22;
  static const double radiusPill = 999;

  /// Builds a themed [ThemeData] with the [AppColors] extension attached.
  static ThemeData build({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    final isDark = brightness == Brightness.dark;
    final c = isDark ? AppColors.dark(accent) : AppColors.light(accent);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      fontFamily: 'SF Pro Display',
      extensions: [c],
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent.color,
        brightness: brightness,
        primary: c.primary,
        surface: c.surface,
        error: c.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent),
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(color: c.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: 0,
          // No full-width minimumSize here: a Size.fromHeight() default would
          // force infinite width on any ElevatedButton placed inside a Row.
          // Full-width CTAs use the PrimaryButton widget, which sizes itself.
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inkCard,
        contentTextStyle: TextStyle(color: c.onInk),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    );
  }

  // ----------------------------------------------------------------------
  // Legacy tokens (dark theme) — kept for not-yet-migrated screens.
  // ----------------------------------------------------------------------
  static const Color primary = Color(0xFFF59E0B);
  static const Color primaryDark = Color(0xFFD97706);
  static const Color primaryLight = Color(0xFFFFD166);

  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF141420);
  static const Color surface2 = Color(0xFF1E1E2E);
  static const Color surface3 = Color(0xFF252538);
  static const Color card = Color(0xFF1A1A28);

  static const Color border = Color(0xFF2A2A3E);
  static const Color border2 = Color(0xFF3A3A52);

  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF555570);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF6366F1);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2E), Color(0xFF141420)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF141420)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Legacy dark theme (not-yet-migrated screens still reference this).
  static ThemeData get dark => build(
        brightness: Brightness.dark,
        accent: AppAccent.camel,
      );
}
