import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/l10n/generated/app_localizations.dart';
import 'package:nova_access_scale/screens/preset_editor_screen.dart';
import 'package:nova_access_scale/theme/app_theme.dart';

Widget _host() => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: const PresetEditorScreen(),
);

void main() {
  testWidgets('exposes a visible, accessible "Name" label for the field', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    // The standalone label node screen readers rely on (a TextField's
    // InputDecoration label does not reach the accessibility node).
    expect(find.text('Name'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('exposes labeled weight controls and no slider', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('Target weight in grams'), findsOneWidget);
    expect(find.bySemanticsLabel('Decrease by 10 grams'), findsOneWidget);
    expect(find.bySemanticsLabel('Increase by 1 gram'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
  });
}
