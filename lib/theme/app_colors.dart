import 'package:flutter/material.dart';

/// Semantic color tokens for the app, exposed as a typed [ThemeExtension].
///
/// Widgets must read colors from here (via `context.colors`) and never hardcode
/// raw hex values — this is the single place brand color decisions live.
///
/// Every text-bearing token below meets WCAG AAA (>= 7:1 for normal text,
/// >= 4.5:1 for large text) against the surfaces it is used on. The ratios are
/// taken from the brand contrast matrix and re-verified for the colors added
/// here (success / warning / accentFill). Tokens documented as "decorative"
/// must only be used for icons, fills, borders, and large graphics — never for
/// body or small text.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.heading,
    required this.accentText,
    required this.accentDecorative,
    required this.accentFill,
    required this.onAccentFill,
    required this.border,
    required this.success,
    required this.warning,
    required this.isHighContrast,
  });

  /// Screen background.
  final Color background;

  /// Raised surface (cards, sheets) sitting on [background].
  final Color surface;

  /// Default body / primary text. AAA on [background] and [surface].
  final Color textPrimary;

  /// Secondary / supporting text. AAA on [background] and [surface].
  final Color textSecondary;

  /// Headings and titles.
  final Color heading;

  /// Text-capable accent (links, accented labels). AAA on [background].
  final Color accentText;

  /// Decorative accent for icons / fills / large graphics. NOT for text.
  final Color accentDecorative;

  /// Fill color for primary action surfaces (filled buttons).
  final Color accentFill;

  /// Text / icon color rendered on top of [accentFill]. AAA on [accentFill].
  final Color onAccentFill;

  /// Dividers, outlines, and disabled affordances.
  final Color border;

  /// Success signal (e.g. target reached). Supplemental to audio/haptic/text.
  final Color success;

  /// Warning signal (e.g. over target). Supplemental to audio/haptic/text.
  final Color warning;

  /// Whether this palette is a high-contrast variant.
  final bool isHighContrast;

  /// Light theme — bg #FFFFFF. Ratios per brand matrix.
  static const BrandColors light = BrandColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF3F4F6),
    textPrimary: Color(0xFF111111), // 18.9:1 on white — AAA
    textSecondary: Color(0xFF4B5563), // 7.6:1 on white — AAA
    heading: Color(0xFF06142E), // 18.3:1 on white — AAA
    accentText: Color(0xFF164E63), // 9.1:1 on white — AAA
    accentDecorative: Color(0xFF0E7490), // deep teal — decorative only
    accentFill: Color(0xFF06142E), // navy fill
    onAccentFill: Color(0xFFFFFFFF), // 18.3:1 on navy — AAA
    border: Color(0xFF6B7280), // neutral gray — decorative
    success: Color(0xFF14532D), // 9.1:1 on white — AAA
    warning: Color(0xFF991B1B), // 8.3:1 on white — AAA
    isHighContrast: false,
  );

  /// Dark theme — bg #06142E. Ratios per brand matrix.
  static const BrandColors dark = BrandColors(
    background: Color(0xFF06142E),
    surface: Color(0xFF0B1F3A),
    textPrimary: Color(0xFFFFFFFF), // 18.3 / 16.5:1 — AAA
    textSecondary: Color(0xFFAEB4BE), // 8.8 / 7.9:1 — AAA
    heading: Color(0xFFFFFFFF),
    accentText: Color(0xFF22D3EE), // 10.1 / 9.1:1 — AAA
    accentDecorative: Color(0xFF0E7490),
    accentFill: Color(0xFF22D3EE), // turquoise fill
    onAccentFill: Color(0xFF06142E), // 10.1:1 on turquoise — AAA
    border: Color(0xFF3B4A63),
    success: Color(0xFF4ADE80), // 10.5:1 on navy — AAA
    warning: Color(0xFFFCA5A5), // 9.6:1 on navy — AAA
    isHighContrast: false,
  );

  /// High-contrast comfort: white on black (21:1). Low-vision glare reduction.
  static const BrandColors hcWhiteOnBlack = BrandColors(
    background: Color(0xFF000000),
    surface: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF), // 21:1
    textSecondary: Color(0xFFE5E7EB), // ~17:1 — AAA
    heading: Color(0xFFFFFFFF),
    accentText: Color(0xFF67E8F9), // brighter turquoise — AAA
    accentDecorative: Color(0xFF22D3EE),
    accentFill: Color(0xFFFFFFFF),
    onAccentFill: Color(0xFF000000), // 21:1
    border: Color(0xFFFFFFFF),
    success: Color(0xFF86EFAC),
    warning: Color(0xFFFCA5A5),
    isHighContrast: true,
  );

  /// High-contrast comfort: black on comfort-yellow (#FFD400) (~14.6:1).
  static const BrandColors hcBlackOnYellow = BrandColors(
    background: Color(0xFFFFD400),
    surface: Color(0xFFFFD400),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF000000),
    heading: Color(0xFF000000),
    accentText: Color(0xFF000000),
    accentDecorative: Color(0xFF000000),
    accentFill: Color(0xFF000000),
    onAccentFill: Color(0xFFFFD400),
    border: Color(0xFF000000),
    success: Color(0xFF000000),
    warning: Color(0xFF000000),
    isHighContrast: true,
  );

  @override
  BrandColors copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? heading,
    Color? accentText,
    Color? accentDecorative,
    Color? accentFill,
    Color? onAccentFill,
    Color? border,
    Color? success,
    Color? warning,
    bool? isHighContrast,
  }) {
    return BrandColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      heading: heading ?? this.heading,
      accentText: accentText ?? this.accentText,
      accentDecorative: accentDecorative ?? this.accentDecorative,
      accentFill: accentFill ?? this.accentFill,
      onAccentFill: onAccentFill ?? this.onAccentFill,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      isHighContrast: isHighContrast ?? this.isHighContrast,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      heading: Color.lerp(heading, other.heading, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentDecorative: Color.lerp(
        accentDecorative,
        other.accentDecorative,
        t,
      )!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      onAccentFill: Color.lerp(onAccentFill, other.onAccentFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      isHighContrast: t < 0.5 ? isHighContrast : other.isHighContrast,
    );
  }
}

/// Convenience access to [BrandColors] from a [BuildContext].
extension BrandColorsContext on BuildContext {
  /// The active semantic color tokens. Throws if the extension is missing,
  /// which only happens if a widget is built outside the app theme.
  BrandColors get colors => Theme.of(this).extension<BrandColors>()!;
}
