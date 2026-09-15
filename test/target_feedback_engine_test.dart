import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/target_feedback_engine.dart';

void main() {
  const engine = TargetFeedbackEngine();

  FeedbackEvaluation eval(double current, int target) =>
      engine.evaluate(currentWeight: current, targetWeightGrams: target);

  group('guards', () {
    test('target of zero is idle with no cadence', () {
      final e = eval(0, 0);
      expect(e.state, TargetState.idle);
      expect(e.cadence, isNull);
    });

    test('negative target is idle', () {
      expect(eval(5, -10).state, TargetState.idle);
    });
  });

  group('reached tolerance (+/- 0.05 g)', () {
    test('exactly on target is reached', () {
      expect(eval(18, 18).state, TargetState.reached);
    });

    test('0.05 g under is reached', () {
      expect(eval(17.95, 18).state, TargetState.reached);
    });

    test('0.05 g over is reached', () {
      expect(eval(18.05, 18).state, TargetState.reached);
    });

    test('0.1 g under is approaching, not reached', () {
      final e = eval(17.9, 18);
      expect(e.state, TargetState.approaching);
      expect(e.remainingGrams, closeTo(0.1, 1e-9));
    });

    test('0.1 g over is over target', () {
      final e = eval(18.1, 18);
      expect(e.state, TargetState.over);
      expect(e.overByGrams, closeTo(0.1, 1e-9));
    });

    test('reached carries no cadence', () {
      expect(eval(18, 18).cadence, isNull);
    });
  });

  group('over target', () {
    test('reports grams over to 0.1 g', () {
      final e = eval(21, 18);
      expect(e.state, TargetState.over);
      expect(e.overByGrams, closeTo(3.0, 1e-9));
      expect(e.cadence, isNull);
    });

    test('reports a sub-gram overshoot (no rounding)', () {
      expect(eval(18.6, 18).overByGrams, closeTo(0.6, 1e-9));
    });
  });

  group('approaching cadence', () {
    test('far from target uses the slowest interval', () {
      final e = eval(0, 100);
      expect(e.state, TargetState.approaching);
      expect(e.cadence, engine.maxInterval);
      expect(e.remainingGrams, closeTo(100.0, 1e-9));
    });

    test('cadence shortens as weight approaches the target', () {
      final far = eval(10, 100).cadence!;
      final mid = eval(50, 100).cadence!;
      final near = eval(90, 100).cadence!;
      expect(far.inMilliseconds, greaterThan(mid.inMilliseconds));
      expect(mid.inMilliseconds, greaterThan(near.inMilliseconds));
      expect(
        near.inMilliseconds,
        greaterThanOrEqualTo(engine.minInterval.inMilliseconds),
      );
    });

    test('remaining grams are reported to 0.1 g (no rounding)', () {
      expect(eval(13.4, 18).remainingGrams, closeTo(4.6, 1e-9));
    });

    test('negative weight clamps the remaining fraction (slowest cadence)', () {
      expect(eval(-10, 100).cadence, engine.maxInterval);
    });
  });
}
