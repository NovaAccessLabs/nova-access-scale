import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds [ThemeData] from the semantic [BrandColors] tokens.
///
/// One entry point — [build] — produces a fully themed [ThemeData] from a
/// resolved [BrandColors] palette. All component themes read from that token
/// set, so no widget needs to reference a raw color.
abstract final class AppTheme {
  /// Minimum interactive height. Comfortably exceeds the 48dp accessibility
  /// minimum so controls remain easy to hit for users with low vision or
  /// motor differences.
  static const double minTouchTarget = 56;

  /// Standard corner radius (slightly rounded, per brand "flat with slightly
  /// rounded corners").
  static const double radius = 14;

  static ThemeData light() =>
      build(colors: BrandColors.light, brightness: Brightness.light);

  static ThemeData dark() =>
      build(colors: BrandColors.dark, brightness: Brightness.dark);

  static ThemeData highContrastLight() =>
      build(colors: BrandColors.hcBlackOnYellow, brightness: Brightness.light);

  static ThemeData highContrastDark() =>
      build(colors: BrandColors.hcWhiteOnBlack, brightness: Brightness.dark);

  static ThemeData build({
    required BrandColors colors,
    required Brightness brightness,
  }) {
    final c = colors;
    final textTheme = AppTypography.textTheme(c);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.accentFill,
      onPrimary: c.onAccentFill,
      secondary: c.accentText,
      onSecondary: c.background,
      error: c.warning,
      onError: brightness == Brightness.dark
          ? const Color(0xFF06142E)
          : const Color(0xFFFFFFFF),
      surface: c.surface,
      onSurface: c.textPrimary,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[c],
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: AppTypography.uiFontFamily,
      textTheme: textTheme,
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      iconTheme: IconThemeData(color: c.textPrimary, size: 28),
      // Keep the 48dp+ padded tap target on every Material control.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      // Respect the OS "reduce motion" setting for route transitions.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _ReducedMotionPageTransitionsBuilder(),
          TargetPlatform.iOS: _ReducedMotionPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.heading,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: c.heading, size: 28),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: c.border),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accentFill,
          foregroundColor: c.onAccentFill,
          minimumSize: const Size(64, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontWeight: AppTypography.semiBold,
            fontSize: 18,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accentText,
          minimumSize: const Size(64, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: c.border, width: 1.5),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontWeight: AppTypography.semiBold,
            fontSize: 18,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentText,
          minimumSize: const Size(64, minTouchTarget),
          textStyle: const TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontWeight: AppTypography.semiBold,
            fontSize: 16,
          ),
        ),
      ),
      // Icon-only buttons (app bar actions, preset row actions) are not covered
      // by the button themes above and were measuring ~46dp on device — under
      // the 48dp platform minimum, and well under this app's own target.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        minVerticalPadding: 14,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.onAccentFill
              : c.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.accentFill : c.surface,
        ),
        trackOutlineColor: WidgetStateProperty.all(c.border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Skips the page transition animation when the OS "reduce motion" preference
/// is on; otherwise uses the default zoom transition.
class _ReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _ReducedMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return const ZoomPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
