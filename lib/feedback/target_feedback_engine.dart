import 'package:flutter/foundation.dart';

/// The user's position relative to the target weight.
enum TargetState {
  /// No usable target (target <= 0). No cadence.
  idle,

  /// Below the reached tolerance. Feedback pulses at [FeedbackEvaluation.cadence].
  approaching,

  /// Within +/- the reached tolerance of the target.
  reached,

  /// More than the reached tolerance above the target.
  over,
}

/// The result of evaluating the current weight against the target. Carries
/// everything the feedback services and UI need, so derived numbers
/// (grams remaining / grams over) have a single source of truth.
@immutable
class FeedbackEvaluation {
  const FeedbackEvaluation({
    required this.state,
    required this.cadence,
    required this.remainingGrams,
    required this.overByGrams,
  });

  final TargetState state;

  /// Interval between feedback pulses while [state] is [TargetState.approaching];
  /// null otherwise.
  final Duration? cadence;

  /// Grams left to reach the target (>= 0), to 0.1 g. Meaningful while approaching.
  final double remainingGrams;

  /// Grams above the target (>= 0), to 0.1 g. Meaningful while over.
  final double overByGrams;

  @override
  bool operator ==(Object other) =>
      other is FeedbackEvaluation &&
      other.state == state &&
      other.cadence == cadence &&
      other.remainingGrams == remainingGrams &&
      other.overByGrams == overByGrams;

  @override
  int get hashCode => Object.hash(state, cadence, remainingGrams, overByGrams);

  @override
  String toString() =>
      'FeedbackEvaluation($state, cadence: $cadence, remaining: $remainingGrams, over: $overByGrams)';
}

/// Pure, stateless mapping from (current weight, target) to a [FeedbackEvaluation].
///
/// Rules (per PRD "Feedback System"):
///  * target <= 0 -> [TargetState.idle], no cadence (guards divide-by-zero).
///  * within +/- [reachedToleranceGrams] of target -> [TargetState.reached].
///  * more than the tolerance above target -> [TargetState.over].
///  * otherwise [TargetState.approaching]: cadence is derived from the
///    *remaining percentage* — the smaller the fraction remaining, the shorter
///    the interval (faster pulses).
class TargetFeedbackEngine {
  const TargetFeedbackEngine({
    this.reachedToleranceGrams = 0.05,
    this.minInterval = const Duration(milliseconds: 150),
    this.maxInterval = const Duration(milliseconds: 1500),
  });

  /// Half-width of the "reached" band, in grams. 0.05 g means "reached" when the
  /// weight rounds to the target at the 0.1 g display precision — so a full
  /// 0.1 g short (e.g. 17.9 for a target of 18) still reads as 0.1 g remaining.
  final double reachedToleranceGrams;

  /// Fastest pulse interval (just before the target).
  final Duration minInterval;

  /// Slowest pulse interval (target still far away).
  final Duration maxInterval;

  FeedbackEvaluation evaluate({
    required double currentWeight,
    required int targetWeightGrams,
  }) {
    if (targetWeightGrams <= 0) {
      return const FeedbackEvaluation(
        state: TargetState.idle,
        cadence: null,
        remainingGrams: 0,
        overByGrams: 0,
      );
    }

    final diff = currentWeight - targetWeightGrams;
    // Small epsilon so a weight exactly at the tolerance edge (e.g. 0.1 g over)
    // counts as reached despite floating-point representation error.
    const epsilon = 1e-6;

    if (diff > reachedToleranceGrams + epsilon) {
      return FeedbackEvaluation(
        state: TargetState.over,
        cadence: null,
        remainingGrams: 0,
        overByGrams: diff,
      );
    }

    if (diff >= -reachedToleranceGrams - epsilon) {
      return const FeedbackEvaluation(
        state: TargetState.reached,
        cadence: null,
        remainingGrams: 0,
        overByGrams: 0,
      );
    }

    // Approaching: weight is below the reached band.
    final remaining = targetWeightGrams - currentWeight;
    final remainingFraction = (remaining / targetWeightGrams).clamp(0.0, 1.0);
    return FeedbackEvaluation(
      state: TargetState.approaching,
      cadence: _cadenceForFraction(remainingFraction),
      remainingGrams: remaining,
      overByGrams: 0,
    );
  }

  Duration _cadenceForFraction(double fraction) {
    final span = maxInterval.inMilliseconds - minInterval.inMilliseconds;
    final ms = minInterval.inMilliseconds + span * fraction;
    return Duration(milliseconds: ms.round());
  }
}
