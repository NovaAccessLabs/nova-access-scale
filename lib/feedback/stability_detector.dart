/// Detects the pauses that gate spoken announcements.
///
/// A pause is when the weight stays within +/- [toleranceGrams] of a stable
/// anchor for at least [holdDuration] (0.5 g for 1000 ms). Exactly one
/// pause is reported per stable region: after a pause fires, the weight must
/// move beyond the tolerance (the user adds or removes weight) before another
/// pause can be reported. This prevents repeated announcements while the scale
/// sits still.
///
/// Time is supplied by the caller as a monotonic [elapsed] [Duration], so the
/// logic is fully deterministic and unit-testable without real clocks.
class StabilityDetector {
  StabilityDetector({
    this.toleranceGrams = 0.5,
    this.holdDuration = const Duration(milliseconds: 1000),
  });

  final double toleranceGrams;
  final Duration holdDuration;

  double? _anchorWeight;
  Duration _anchorTime = Duration.zero;
  bool _announcedForCurrentRegion = false;

  /// Feeds a weight sample taken at [elapsed]. Returns true exactly once when a
  /// new pause is confirmed.
  bool addSample(double grams, Duration elapsed) {
    final anchor = _anchorWeight;
    if (anchor == null || (grams - anchor).abs() > toleranceGrams) {
      // First sample, or movement beyond tolerance: start a new region.
      _anchorWeight = grams;
      _anchorTime = elapsed;
      _announcedForCurrentRegion = false;
      return false;
    }

    // Still within tolerance of the anchor.
    if (_announcedForCurrentRegion) return false;
    if (elapsed - _anchorTime >= holdDuration) {
      _announcedForCurrentRegion = true;
      return true;
    }
    return false;
  }

  /// Clears all state (e.g. on disconnect or when the target changes).
  void reset() {
    _anchorWeight = null;
    _anchorTime = Duration.zero;
    _announcedForCurrentRegion = false;
  }
}
