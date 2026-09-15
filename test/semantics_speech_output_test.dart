import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/semantics_speech_output.dart';

void main() {
  test('is unavailable until a renderer attaches', () {
    final output = SemanticsSpeechOutput();
    expect(output.isAvailable, isFalse);
    output.attachRenderer();
    expect(output.isAvailable, isTrue);
    output.detachRenderer();
    expect(output.isAvailable, isFalse);
  });

  test(
    'repeating the same text 3+ times in a row still changes the raw '
    'value every time, so the live region re-announces on every repeat '
    '(regression: a strip-then-reappend nonce reproduces the same string '
    'on the 3rd+ repeat, and ValueNotifier silently skips notifying when '
    'the new value equals the current one — TalkBack then says nothing)',
    () async {
      final output = SemanticsSpeechOutput()..attachRenderer();
      final seenValues = <String?>[];
      output.message.addListener(() => seenValues.add(output.message.value));

      for (var i = 0; i < 5; i++) {
        await output.announce('Target reached', languageCode: 'en');
      }

      // Every one of the 5 identical announcements must have produced a raw
      // value different from the one right before it (a correct toggle just
      // alternates between two strings — A, B, A, B, A — it doesn't need 5
      // globally distinct values), or ValueNotifier would have swallowed the
      // notification and TalkBack would never re-read it.
      expect(seenValues, hasLength(5));
      for (var i = 1; i < seenValues.length; i++) {
        expect(
          seenValues[i],
          isNot(seenValues[i - 1]),
          reason: 'repeat #$i must differ from the previous raw value',
        );
      }
      for (final value in seenValues) {
        expect(value?.replaceAll('​', ''), 'Target reached');
      }
    },
  );

  test('switching to different text always announces immediately', () async {
    final output = SemanticsSpeechOutput()..attachRenderer();
    var notifyCount = 0;
    output.message.addListener(() => notifyCount++);

    await output.announce('Target reached', languageCode: 'en');
    await output.announce('5.0 grams remaining', languageCode: 'en');
    await output.announce('Target reached', languageCode: 'en');

    expect(notifyCount, 3);
  });

  test('does nothing when no renderer is attached', () async {
    final output = SemanticsSpeechOutput();
    await output.announce('Target reached', languageCode: 'en');
    expect(output.message.value, isNull);
  });

  test('stop clears the live region', () async {
    final output = SemanticsSpeechOutput()..attachRenderer();
    await output.announce('Target reached', languageCode: 'en');
    await output.stop();
    expect(output.message.value, isNull);
  });
}
