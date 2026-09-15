import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/theme/app_colors.dart';
import 'package:nova_access_scale/theme/app_theme.dart';

void main() {
  test('highContrastLight uses the black-on-yellow palette', () {
    final theme = AppTheme.highContrastLight();
    expect(theme.extension<BrandColors>(), BrandColors.hcBlackOnYellow);
    expect(theme.brightness, Brightness.light);
  });

  test('highContrastDark uses the white-on-black palette', () {
    final theme = AppTheme.highContrastDark();
    expect(theme.extension<BrandColors>(), BrandColors.hcWhiteOnBlack);
    expect(theme.brightness, Brightness.dark);
  });
}
