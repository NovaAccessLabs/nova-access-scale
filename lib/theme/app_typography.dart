import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography roles for the app.
///
/// Two families are bundled (see pubspec.yaml):
///  * [uiFontFamily] — Manrope: the primary UI face (chrome, labels, buttons).
///  * [readingFontFamily] — Atkinson Hyperlegible: the reading face used for the
///    large weight readout and prominent status text, because its letterforms
///    are designed to maximise distinction for low-vision readers.
///
/// Only the brand-recommended Manrope weights are bundled (Regular 400,
/// Medium 500, SemiBold 600) — never request a weight that is not bundled, or
/// the engine will synthesize a faux-bold.
abstract final class AppTypography {
  static const String uiFontFamily = 'Manrope';
  static const String readingFontFamily = 'Atkinson Hyperlegible';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;

  /// Builds the app [TextTheme] with token colors baked in. UI text uses
  /// Manrope; the display sizes (used for the weight readout) use Atkinson
  /// Hyperlegible.
  static TextTheme textTheme(BrandColors c) {
    return TextTheme(
      // Display sizes: large numerals (weight readout). Reading face.
      displayLarge: TextStyle(
        fontFamily: readingFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 64,
        height: 1.05,
        color: c.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: readingFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 48,
        height: 1.05,
        color: c.textPrimary,
      ),
      // Headlines / titles: Manrope SemiBold, heading token.
      headlineLarge: TextStyle(
        fontFamily: uiFontFamily,
        fontWeight: semiBold,
        fontSize: 30,
        color: c.heading,
      ),
      headlineMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontWeight: semiBold,
        fontSize: 26,
        color: c.heading,
      ),
      headlineSmall: TextStyle(
        fontFamily: uiFontFamily,
        fontWeight: semiBold,
        fontSize: 22,
        color: c.heading,
      ),
      titleLarge: TextStyle(
        fontFamily: uiFontFamily,
        fontWeight: semiBold,
        fontSize: 20,
        color: c.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontWeight: medium,
        fontSize: 18,
        color: c.textPrimary,
      ),
      // Body: Atkinson Hyperlegible reading face for substantial text.
      bodyLarge: TextStyle(
        fontFamily: readingFontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 18,
        height: 1.4,
        color: c.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: readingFontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.4,
        color: c.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: readingFontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.4,
        color: c.textSecondary,
      ),
      // Labels: Manrope Medium (buttons, controls).
      labelLarge: TextStyle(
        fontFamily: uiFontFamily,
        fontWeight: medium,
        fontSize: 16,
        color: c.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: uiFontFamily,
        fontWeight: medium,
        fontSize: 14,
        color: c.textSecondary,
      ),
    );
  }

  /// Style for the prominent live weight readout. Tabular figures keep the
  /// number from shifting horizontally as digits change.
  static TextStyle weightReadout(BrandColors c) {
    return TextStyle(
      fontFamily: readingFontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 72,
      height: 1.0,
      color: c.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
