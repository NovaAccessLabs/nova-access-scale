import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/feedback_outputs.dart';
import 'package:nova_access_scale/feedback/speech_router.dart';
import 'package:nova_access_scale/models/speech_output_mode.dart';

/// Records what the app's own TTS engine was asked to say.
class _FakeTts implements SpeechOutput {
  bool available = true;
  final List<String> spoken = [];
  int stopCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<void> announce(String text, {required String languageCode}) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async => stopCalls++;
}

/// Stands in for the accessibility (live-region) layer. [isAvailable] models
/// "a LiveRegionAnnouncer is mounted to render the text".
class _FakeSemantics implements SpeechOutput {
  bool available = true;
  bool throwOnAnnounce = false;
  final List<String> announced = [];

  @override
  bool get isAvailable => available;

  @override
  Future<void> announce(String text, {required String languageCode}) async {
    if (throwOnAnnounce) throw StateError('accessibility channel failed');
    announced.add(text);
  }

  @override
  Future<void> stop() async {}
}

void main() {
  late _FakeTts tts;
  late _FakeSemantics semantics;
  late SpeechRouter router;

  setUp(() {
    tts = _FakeTts();
    semantics = _FakeSemantics();
    router = SpeechRouter(tts: tts, semantics: semantics);
  });

  Future<void> say([String text = 'five grams remaining']) =>
      router.announce(text, languageCode: 'en');

  group('screenReader mode (default)', () {
    test('is the default mode', () {
      expect(router.mode, SpeechOutputMode.screenReader);
    });

    test(
      'announces through the accessibility layer and stays quiet itself',
      () async {
        router.screenReaderActive = true;
        await say();

        // The whole point: the user's own voice speaks, the app's does not talk
        // over it.
        expect(semantics.announced, ['five grams remaining']);
        expect(tts.spoken, isEmpty);
      },
    );

    test(
      'falls back to the app voice when no screen reader is active',
      () async {
        router.screenReaderActive = false;
        await say();

        // A low-vision user on magnification with TalkBack off must not be left
        // in silence.
        expect(tts.spoken, ['five grams remaining']);
        expect(semantics.announced, isEmpty);
      },
    );

    test('speaks itself if the accessibility route is unavailable', () async {
      // e.g. no FlutterView pushed in yet. Silence is never the fallback.
      router.screenReaderActive = true;
      semantics.available = false;
      await say();

      expect(tts.spoken, ['five grams remaining']);
      expect(semantics.announced, isEmpty);
    });
  });

  group('appVoice mode', () {
    setUp(() => router.mode = SpeechOutputMode.appVoice);

    test('uses the app voice even while a screen reader is active', () async {
      router.screenReaderActive = true;
      await say();

      expect(tts.spoken, ['five grams remaining']);
      expect(semantics.announced, isEmpty);
    });

    test('uses the app voice with no screen reader', () async {
      router.screenReaderActive = false;
      await say();

      expect(tts.spoken, ['five grams remaining']);
      expect(semantics.announced, isEmpty);
    });
  });

  group('both mode', () {
    setUp(() => router.mode = SpeechOutputMode.both);

    test('announces and speaks when a screen reader is active', () async {
      router.screenReaderActive = true;
      await say();

      expect(semantics.announced, ['five grams remaining']);
      expect(tts.spoken, ['five grams remaining']);
    });

    test('speaks only, with no screen reader to announce through', () async {
      router.screenReaderActive = false;
      await say();

      expect(tts.spoken, ['five grams remaining']);
      expect(semantics.announced, isEmpty);
    });
  });

  group('isAvailable', () {
    test('is true with no TTS engine when the screen reader carries it', () {
      // Without this the coordinator would drop the announcement entirely, so a
      // device with no TTS engine installed would go silent for a TalkBack user.
      tts.available = false;
      router.screenReaderActive = true;

      expect(router.isAvailable, isTrue);
    });

    test('is false when neither route can speak', () {
      tts.available = false;
      router.screenReaderActive = false;

      expect(router.isAvailable, isFalse);
    });

    test('is true from the app voice alone', () {
      router.screenReaderActive = false;

      expect(router.isAvailable, isTrue);
    });
  });

  test('a failing route does not escape as an unhandled error', () async {
    // The coordinator calls announce() without awaiting it, so an escaping
    // error would surface as an unhandled async exception rather than being
    // swallowed. Speech is optional; weighing must continue.
    router.screenReaderActive = true;
    semantics.throwOnAnnounce = true;

    await expectLater(say(), completes);
  });

  test('stop only stops app-owned speech', () async {
    // The screen reader's queue is not ours to flush.
    await router.stop();

    expect(tts.stopCalls, 1);
  });
}
