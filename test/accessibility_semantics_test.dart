import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/feedback_outputs.dart';
import 'package:nova_access_scale/feedback/semantics_speech_output.dart';
import 'package:nova_access_scale/feedback/speech_router.dart';
import 'package:nova_access_scale/l10n/generated/app_localizations.dart';
import 'package:nova_access_scale/theme/app_theme.dart';
import 'package:nova_access_scale/widgets/labeled_option_picker.dart';

/// Screen-reader guarantees found missing in the on-device TalkBack audit
/// (2026-08-11). None of these are visible in a screenshot, so they need
/// asserting or they regress unnoticed.

class _FakeTts implements SpeechOutput {
  final List<String> spoken = [];
  int stopCalls = 0;

  @override
  bool get isAvailable => true;
  @override
  Future<void> announce(String text, {required String languageCode}) async =>
      spoken.add(text);
  @override
  Future<void> stop() async => stopCalls++;
}

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('option chips expose a tap action, not just a button flag', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var picked = '';

    await tester.pumpWidget(
      _wrap(
        LabeledOptionPicker<String>(
          label: 'Speech output',
          selected: 'a',
          onChanged: (v) => picked = v,
          options: const [
            PickerOption('a', 'Screen reader voice'),
            PickerOption('b', 'App voice'),
          ],
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('App voice'));
    expect(node.flagsCollection.isButton, isTrue);
    // Without the action, TalkBack's double-tap still works (it synthesizes a
    // touch) but switch access and braille displays activate via ACTION_CLICK
    // and get nothing.
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'a button node with no tap action is not activatable',
    );

    tester.semantics.performAction(
      find.semantics.byLabel('App voice'),
      SemanticsAction.tap,
    );
    await tester.pump();
    expect(picked, 'b');

    handle.dispose();
  });

  testWidgets('selection is exposed as a flag, never colour alone', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(
        LabeledOptionPicker<String>(
          label: 'Speech output',
          selected: 'a',
          onChanged: (_) {},
          options: const [
            PickerOption('a', 'Screen reader voice'),
            PickerOption('b', 'App voice'),
          ],
        ),
      ),
    );

    // `isSelected` is a Tristate, not a bool: "not selected" and "selection is
    // not a concept here" are different things to a screen reader, and only
    // the first one makes TalkBack say "selected" / "not selected".
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Screen reader voice'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('App voice'))
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );

    handle.dispose();
  });

  test('stopping speech clears the accessibility route too', () async {
    // Regression: stop() only stopped TTS, so the last announcement stayed in
    // the semantics tree. On device, "Over target by 0.3 grams" was still the
    // first node on the connection screen after disconnecting.
    final tts = _FakeTts();
    final semantics = SemanticsSpeechOutput()..attachRenderer();
    final router = SpeechRouter(tts: tts, semantics: semantics);

    await semantics.announce('Over target by 0.3 grams', languageCode: 'en');
    expect(semantics.message.value, isNotNull);

    await router.stop();

    expect(
      semantics.message.value,
      isNull,
      reason: 'stale text must not linger',
    );
    expect(tts.stopCalls, 1);
  });
}
