import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/feedback_coordinator.dart';
import 'package:nova_access_scale/feedback/feedback_outputs.dart';
import 'package:nova_access_scale/feedback/target_feedback_engine.dart';
import 'package:nova_access_scale/models/feedback_mode.dart';

class _FakePulse implements PulseFeedbackOutput {
  int approachCount = 0;
  int reachedCount = 0;
  int overCount = 0;

  @override
  Future<void> approachPulse() async => approachCount++;
  @override
  Future<void> reached() async => reachedCount++;
  @override
  Future<void> overTarget() async => overCount++;
}

class _FakeSpeech implements SpeechOutput {
  bool available = true;
  final List<String> spoken = [];

  @override
  bool get isAvailable => available;
  @override
  Future<void> announce(String text, {required String languageCode}) async =>
      spoken.add(text);
  @override
  Future<void> stop() async {}
}

FeedbackCoordinator _coordinator({
  required _FakePulse audio,
  required _FakePulse haptic,
  required _FakeSpeech speech,
  FeedbackMode mode = FeedbackMode.audioVibration,
  TargetFeedbackEngine engine = const TargetFeedbackEngine(),
}) {
  final c = FeedbackCoordinator(
    audio: audio,
    haptic: haptic,
    speech: speech,
    engine: engine,
  )..announcementBuilder = (e) => 'remaining ${e.remainingGrams}';
  c.updateConfig(mode: mode, speechEnabled: true);
  return c;
}

void main() {
  test('emits the reached cue once on entering reached', () {
    final audio = _FakePulse();
    final haptic = _FakePulse();
    final c = _coordinator(audio: audio, haptic: haptic, speech: _FakeSpeech())
      ..reachedConfirmDelay = Duration.zero;
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(18.0);
    c.onWeightSample(18.03); // still reached (within +/- 0.05 g)

    expect(audio.reachedCount, 1);
    expect(haptic.reachedCount, 1);
    expect(audio.overCount, 0);
  });

  test('emits the over cue once, after the confirm delay', () {
    final audio = _FakePulse();
    final c = _coordinator(
      audio: audio,
      haptic: _FakePulse(),
      speech: _FakeSpeech(),
    )..overConfirmDelay = const Duration(milliseconds: 600);
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(25, elapsed: Duration.zero); // over -> arms the debounce
    expect(audio.overCount, 0); // not confirmed yet
    c.onWeightSample(
      25,
      elapsed: const Duration(milliseconds: 600),
    ); // confirmed
    c.onWeightSample(
      25,
      elapsed: const Duration(milliseconds: 700),
    ); // still over

    expect(audio.overCount, 1);
  });

  test('feedback mode gates which channels fire', () {
    final audio = _FakePulse();
    final haptic = _FakePulse();
    final c = _coordinator(
      audio: audio,
      haptic: haptic,
      speech: _FakeSpeech(),
      mode: FeedbackMode.vibration,
    )..overConfirmDelay = const Duration(milliseconds: 600);
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(25, elapsed: Duration.zero);
    c.onWeightSample(25, elapsed: const Duration(milliseconds: 600));

    expect(audio.overCount, 0); // audio disabled
    expect(haptic.overCount, 1); // vibration enabled
  });

  test(
    'announces grams remaining after the settle delay following a pause',
    () {
      final speech = _FakeSpeech();
      final c = _coordinator(
        audio: _FakePulse(),
        haptic: _FakePulse(),
        speech: speech,
      )..announceSettleDelay = const Duration(milliseconds: 500);
      addTearDown(c.dispose);

      c.setTarget(100);
      c.onWeightSample(50, elapsed: Duration.zero);
      c.onWeightSample(
        50,
        elapsed: const Duration(milliseconds: 1000),
      ); // pause
      // Held, but the 500 ms settle delay has not elapsed yet.
      expect(speech.spoken, isEmpty);
      c.onWeightSample(
        50,
        elapsed: const Duration(milliseconds: 1500),
      ); // settled

      expect(speech.spoken, ['remaining 50.0']);
    },
  );

  test(
    'announces the settled reading taken after the delay, not at the pause',
    () {
      final speech = _FakeSpeech();
      final c = _coordinator(
        audio: _FakePulse(),
        haptic: _FakePulse(),
        speech: speech,
      )..announceSettleDelay = const Duration(milliseconds: 500);
      addTearDown(c.dispose);

      c.setTarget(100);
      c.onWeightSample(50.0, elapsed: Duration.zero);
      c.onWeightSample(
        50.0,
        elapsed: const Duration(milliseconds: 1000),
      ); // pause
      // A flickery scale drifts within tolerance while settling; the value read
      // after the delay is what gets announced.
      c.onWeightSample(50.5, elapsed: const Duration(milliseconds: 1500));

      expect(speech.spoken, [
        'remaining 49.5',
      ]); // 100 - 50.5, the latest reading
    },
  );

  test('drops the pending announcement if the user resumes pouring', () {
    final speech = _FakeSpeech();
    final c = _coordinator(
      audio: _FakePulse(),
      haptic: _FakePulse(),
      speech: speech,
    );
    addTearDown(c.dispose);

    c.setTarget(100);
    c.onWeightSample(50.0, elapsed: Duration.zero);
    c.onWeightSample(
      50.0,
      elapsed: const Duration(milliseconds: 1000),
    ); // pause
    c.onWeightSample(
      60.0,
      elapsed: const Duration(milliseconds: 1200),
    ); // moved
    c.onWeightSample(60.0, elapsed: const Duration(milliseconds: 1700));

    // The stale "remaining 50.0" was dropped, and the new region has not been
    // held long enough to pause again, so nothing is spoken.
    expect(speech.spoken, isEmpty);
  });

  test('settle delay of zero speaks immediately on the pause', () {
    final speech = _FakeSpeech();
    final c = _coordinator(
      audio: _FakePulse(),
      haptic: _FakePulse(),
      speech: speech,
    )..announceSettleDelay = Duration.zero;
    addTearDown(c.dispose);

    c.setTarget(100);
    c.onWeightSample(50, elapsed: Duration.zero);
    c.onWeightSample(50, elapsed: const Duration(milliseconds: 1000));

    expect(speech.spoken, ['remaining 50.0']);
  });

  test('announces reached immediately and over after the confirm delay', () {
    final speech = _FakeSpeech();
    final c =
        _coordinator(audio: _FakePulse(), haptic: _FakePulse(), speech: speech)
          ..reachedConfirmDelay = Duration.zero
          ..overConfirmDelay = const Duration(milliseconds: 600)
          ..announcementBuilder = (e) => switch (e.state) {
            TargetState.approaching => 'remaining ${e.remainingGrams}',
            TargetState.reached => 'reached',
            TargetState.over => 'over ${e.overByGrams}',
            TargetState.idle => null,
          };
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(18.0, elapsed: Duration.zero); // reached -> immediate
    c.onWeightSample(
      20.0,
      elapsed: const Duration(milliseconds: 10),
    ); // over arms
    expect(speech.spoken, ['reached']); // over not announced yet
    c.onWeightSample(
      20.0,
      elapsed: const Duration(milliseconds: 610),
    ); // confirmed

    expect(speech.spoken, ['reached', 'over 2.0']);
  });

  test('ignores a transient overshoot (over feedback is debounced)', () {
    final audio = _FakePulse();
    final speech = _FakeSpeech();
    final c = _coordinator(audio: audio, haptic: _FakePulse(), speech: speech)
      ..reachedConfirmDelay = Duration.zero
      ..overConfirmDelay = const Duration(milliseconds: 600)
      ..announcementBuilder = (e) => switch (e.state) {
        TargetState.reached => 'reached',
        TargetState.over => 'over ${e.overByGrams}',
        _ => null,
      };
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(18.0, elapsed: Duration.zero); // reached
    c.onWeightSample(
      19.0,
      elapsed: const Duration(milliseconds: 100),
    ); // spike over
    c.onWeightSample(
      18.0,
      elapsed: const Duration(milliseconds: 300),
    ); // back, in time
    c.onWeightSample(18.0, elapsed: const Duration(milliseconds: 1500));

    expect(audio.overCount, 0); // never fired the over cue
    expect(speech.spoken, ['reached']); // never announced over
  });

  test('announces over once it stays over past the confirm delay', () {
    final audio = _FakePulse();
    final speech = _FakeSpeech();
    final c = _coordinator(audio: audio, haptic: _FakePulse(), speech: speech)
      ..overConfirmDelay = const Duration(milliseconds: 600)
      ..announcementBuilder = (e) =>
          e.state == TargetState.over ? 'over ${e.overByGrams}' : null;
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(20.0, elapsed: Duration.zero); // over arms
    c.onWeightSample(
      20.0,
      elapsed: const Duration(milliseconds: 300),
    ); // confirming
    expect(audio.overCount, 0);
    c.onWeightSample(
      20.0,
      elapsed: const Duration(milliseconds: 600),
    ); // confirmed

    expect(audio.overCount, 1);
    expect(speech.spoken, ['over 2.0']);
  });

  test('ignores a transient touch of the target (reached is debounced)', () {
    final audio = _FakePulse();
    final speech = _FakeSpeech();
    final c = _coordinator(audio: audio, haptic: _FakePulse(), speech: speech)
      ..reachedConfirmDelay = const Duration(milliseconds: 600)
      ..announcementBuilder = (e) =>
          e.state == TargetState.reached ? 'reached' : null;
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(17.0, elapsed: Duration.zero); // approaching
    c.onWeightSample(
      18.0,
      elapsed: const Duration(milliseconds: 100),
    ); // touches
    c.onWeightSample(
      17.0,
      elapsed: const Duration(milliseconds: 300),
    ); // back, in time
    c.onWeightSample(17.0, elapsed: const Duration(milliseconds: 1000));

    expect(audio.reachedCount, 0); // never fired the reached cue
    expect(speech.spoken, isEmpty); // never announced reached
  });

  test(
    'announces reached once it stays in the band past the confirm delay',
    () {
      final audio = _FakePulse();
      final speech = _FakeSpeech();
      final c = _coordinator(audio: audio, haptic: _FakePulse(), speech: speech)
        ..reachedConfirmDelay = const Duration(milliseconds: 600)
        ..announcementBuilder = (e) =>
            e.state == TargetState.reached ? 'reached' : null;
      addTearDown(c.dispose);

      c.setTarget(18);
      c.onWeightSample(17.0, elapsed: Duration.zero); // approaching
      c.onWeightSample(
        18.0,
        elapsed: const Duration(milliseconds: 100),
      ); // touches
      c.onWeightSample(
        18.0,
        elapsed: const Duration(milliseconds: 300),
      ); // confirming
      expect(audio.reachedCount, 0);
      c.onWeightSample(
        18.0,
        elapsed: const Duration(milliseconds: 700),
      ); // confirmed

      expect(audio.reachedCount, 1);
      expect(speech.spoken, ['reached']);
    },
  );

  test(
    'pouring straight through the target to over never announces reached',
    () {
      final audio = _FakePulse();
      final speech = _FakeSpeech();
      final c = _coordinator(audio: audio, haptic: _FakePulse(), speech: speech)
        ..reachedConfirmDelay = const Duration(milliseconds: 600)
        ..overConfirmDelay = const Duration(milliseconds: 600)
        ..announcementBuilder = (e) => switch (e.state) {
          TargetState.reached => 'reached',
          TargetState.over => 'over ${e.overByGrams}',
          _ => null,
        };
      addTearDown(c.dispose);

      c.setTarget(18);
      c.onWeightSample(17.0, elapsed: Duration.zero); // approaching
      c.onWeightSample(
        18.0,
        elapsed: const Duration(milliseconds: 100),
      ); // brief reached
      c.onWeightSample(
        20.0,
        elapsed: const Duration(milliseconds: 200),
      ); // over, still pouring
      c.onWeightSample(
        20.0,
        elapsed: const Duration(milliseconds: 800),
      ); // sustained over

      expect(audio.reachedCount, 0); // reached never fired on the way through
      expect(speech.spoken, ['over 2.0']); // only over, once confirmed
    },
  );

  test('does not repeat reached on the pause that follows it', () {
    final speech = _FakeSpeech();
    final c =
        _coordinator(audio: _FakePulse(), haptic: _FakePulse(), speech: speech)
          ..reachedConfirmDelay = Duration.zero
          ..announcementBuilder = (e) =>
              e.state == TargetState.reached ? 'reached' : 'other';
    addTearDown(c.dispose);

    c.setTarget(18);
    c.onWeightSample(18.0, elapsed: Duration.zero); // reached -> 'reached'
    c.onWeightSample(
      18.0,
      elapsed: const Duration(milliseconds: 1000),
    ); // pause -> same phrase, suppressed

    expect(speech.spoken, ['reached']);
  });

  test('does not announce when speech is disabled', () {
    final speech = _FakeSpeech();
    final c = _coordinator(
      audio: _FakePulse(),
      haptic: _FakePulse(),
      speech: speech,
    );
    addTearDown(c.dispose);
    c.updateConfig(speechEnabled: false);

    c.setTarget(100);
    c.onWeightSample(50, elapsed: Duration.zero);
    c.onWeightSample(50, elapsed: const Duration(milliseconds: 1000));

    expect(speech.spoken, isEmpty);
  });

  test('does not announce when no TTS engine is available', () {
    final speech = _FakeSpeech()..available = false;
    final c = _coordinator(
      audio: _FakePulse(),
      haptic: _FakePulse(),
      speech: speech,
    );
    addTearDown(c.dispose);

    c.setTarget(100);
    c.onWeightSample(50, elapsed: Duration.zero);
    c.onWeightSample(50, elapsed: const Duration(milliseconds: 1000));

    expect(speech.spoken, isEmpty);
  });

  test('pulses on the cadence while approaching', () async {
    final audio = _FakePulse();
    final c = _coordinator(
      audio: audio,
      haptic: _FakePulse(),
      speech: _FakeSpeech(),
      // Fixed tiny cadence for a fast, deterministic test.
      engine: const TargetFeedbackEngine(
        minInterval: Duration(milliseconds: 10),
        maxInterval: Duration(milliseconds: 10),
      ),
    );
    addTearDown(c.dispose);

    c.setTarget(100);
    c.onWeightSample(50); // approaching -> starts pulse loop
    await Future<void>.delayed(const Duration(milliseconds: 45));
    await c.stop();

    expect(audio.approachCount, greaterThanOrEqualTo(2));
  });

  group('confirmation when the weight stream goes quiet', () {
    // Regression (found on-device): the debounce used to be confirmed only by
    // the *next* sample. A scale that stops streaming once the weight is stable
    // — common power-saving behavior, and what the demo scale does at its
    // ceiling — left the transition pending forever: 100.4 g against an 18 g
    // target reported "0.0 grams remaining" with approach pulses still playing
    // and no over-target warning.

    test('commits a pending over-target with no further samples', () async {
      final audio = _FakePulse();
      final speech = _FakeSpeech();
      final c = _coordinator(audio: audio, haptic: _FakePulse(), speech: speech)
        ..overConfirmDelay = const Duration(milliseconds: 40);
      addTearDown(c.dispose);

      FeedbackEvaluation? pushed;
      c.onEvaluationChanged = (e) => pushed = e;

      c.setTarget(18);
      final immediate = c.onWeightSample(100.4); // over -> arms the debounce
      expect(immediate.state, TargetState.approaching); // still confirming
      expect(audio.overCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(audio.overCount, 1, reason: 'the warning cue must still fire');
      expect(pushed?.state, TargetState.over);
      expect(pushed?.overByGrams, closeTo(82.4, 0.01));
      expect(c.lastEvaluation?.state, TargetState.over);
      expect(speech.spoken, isNotEmpty);
    });

    test('commits a pending reached with no further samples', () async {
      final audio = _FakePulse();
      final c = _coordinator(
        audio: audio,
        haptic: _FakePulse(),
        speech: _FakeSpeech(),
      )..reachedConfirmDelay = const Duration(milliseconds: 40);
      addTearDown(c.dispose);

      c.setTarget(18);
      c.onWeightSample(18.0);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(audio.reachedCount, 1);
      expect(c.lastEvaluation?.state, TargetState.reached);
    });

    test('a sample that leaves the band cancels the pending commit', () async {
      final audio = _FakePulse();
      final c = _coordinator(
        audio: audio,
        haptic: _FakePulse(),
        speech: _FakeSpeech(),
      )..overConfirmDelay = const Duration(milliseconds: 40);
      addTearDown(c.dispose);

      c.setTarget(18);
      c.onWeightSample(25); // over -> arms
      c.onWeightSample(10); // back below before the delay elapses
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // The momentary overshoot must not surface late as a warning.
      expect(audio.overCount, 0);
      expect(c.lastEvaluation?.state, TargetState.approaching);
    });

    test('clearing the target cancels a pending commit', () async {
      final audio = _FakePulse();
      final c = _coordinator(
        audio: audio,
        haptic: _FakePulse(),
        speech: _FakeSpeech(),
      )..overConfirmDelay = const Duration(milliseconds: 40);
      addTearDown(c.dispose);

      c.setTarget(18);
      c.onWeightSample(25);
      c.setTarget(null);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(audio.overCount, 0);
    });
  });
}
