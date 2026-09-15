import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/semantics_speech_output.dart';
import 'package:nova_access_scale/widgets/live_region_announcer.dart';

/// Regression cover for the on-device finding (2026-08-11): announcements were
/// sent with SemanticsService.sendAnnouncement, which Android 16 deprecates and
/// TalkBack ignored — while the router suppressed the app's own voice, leaving
/// a blind user in silence. The accessibility route is now a live region.
void main() {
  Future<void> pump(WidgetTester tester, SemanticsSpeechOutput output) {
    return tester.pumpWidget(
      MaterialApp(
        home: LiveRegionAnnouncer(
          output: output,
          child: const Scaffold(body: Text('body')),
        ),
      ),
    );
  }

  testWidgets('is unavailable until a renderer is mounted', (tester) async {
    final output = SemanticsSpeechOutput();
    addTearDown(output.dispose);

    // Nothing mounted -> the router must not believe speech was delivered.
    expect(output.isAvailable, isFalse);

    await pump(tester, output);
    expect(output.isAvailable, isTrue);
  });

  testWidgets('announces through a live region node', (tester) async {
    final semantics = tester.ensureSemantics();
    final output = SemanticsSpeechOutput();
    addTearDown(output.dispose);
    await pump(tester, output);

    await output.announce('5.0 grams remaining', languageCode: 'en');
    await tester.pump();

    final node = tester.getSemantics(
      find.bySemanticsLabel('5.0 grams remaining'),
    );
    expect(node.label, '5.0 grams remaining');
    expect(
      node.flagsCollection.isLiveRegion,
      isTrue,
      reason:
          'a plain label is only read on focus; the live region is what '
          'makes the screen reader speak it unprompted',
    );
    // Android skips accessibility nodes with empty bounds, so a zero-size node
    // is silent on a real device even though the test tree still exposes it.
    expect(
      node.rect.width * node.rect.height,
      greaterThan(0),
      reason: 'an empty rect is treated as invisible and never announced',
    );
    semantics.dispose();
  });

  testWidgets('repeats an identical message so it is re-read', (tester) async {
    final semantics = tester.ensureSemantics();
    final output = SemanticsSpeechOutput();
    addTearDown(output.dispose);
    await pump(tester, output);

    await output.announce('Target reached', languageCode: 'en');
    await tester.pump();
    final first = output.message.value;

    await output.announce('Target reached', languageCode: 'en');
    await tester.pump();

    // A live region is only re-read when the label actually changes, so an
    // identical repeat has to differ by the invisible nonce.
    expect(output.message.value, isNot(first));
    expect(output.message.value!.replaceAll('​', ''), 'Target reached');
    semantics.dispose();
  });

  testWidgets('drops the message when the renderer unmounts', (tester) async {
    final output = SemanticsSpeechOutput();
    addTearDown(output.dispose);
    await pump(tester, output);
    expect(output.isAvailable, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    // With no renderer the router falls back to app TTS rather than assuming
    // the accessibility layer spoke.
    expect(output.isAvailable, isFalse);
    await output.announce('ignored', languageCode: 'en');
    expect(output.message.value, isNull);
  });
}
