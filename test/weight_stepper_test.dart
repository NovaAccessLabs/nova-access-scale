import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/l10n/generated/app_localizations.dart';
import 'package:nova_access_scale/theme/app_theme.dart';
import 'package:nova_access_scale/widgets/weight_stepper.dart';

/// Hosts a [WeightStepper] with local state so taps can be observed.
class _Host extends StatefulWidget {
  const _Host({this.initial = 18});
  final int initial;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: WeightStepper(
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('uses no Slider (accessibility requirement)', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('exposes labeled step buttons and a target value', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    expect(find.bySemanticsLabel('Decrease by 10 grams'), findsOneWidget);
    expect(find.bySemanticsLabel('Decrease by 1 gram'), findsOneWidget);
    expect(find.bySemanticsLabel('Increase by 1 gram'), findsOneWidget);
    expect(find.bySemanticsLabel('Increase by 10 grams'), findsOneWidget);
    expect(find.bySemanticsLabel('Target 18 grams'), findsOneWidget);
  });

  testWidgets('increment by 1 raises the value', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.bySemanticsLabel('Increase by 1 gram'));
    await tester.pump();
    expect(find.bySemanticsLabel('Target 19 grams'), findsOneWidget);
  });

  testWidgets('decrement by 10 lowers the value', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.bySemanticsLabel('Decrease by 10 grams'));
    await tester.pump();
    expect(find.bySemanticsLabel('Target 8 grams'), findsOneWidget);
  });

  testWidgets('does not go below the minimum of 1 gram', (tester) async {
    await tester.pumpWidget(const _Host(initial: 1));
    await tester.tap(find.bySemanticsLabel('Decrease by 10 grams'));
    await tester.pump();
    expect(find.bySemanticsLabel('Target 1 gram'), findsOneWidget);
  });
}
