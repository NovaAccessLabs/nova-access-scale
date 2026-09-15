import 'package:vibration/vibration.dart';

import 'feedback_outputs.dart';

/// Haptic feedback for the three cues, for users who cannot hear the tones or
/// have audio disabled. Patterns are distinct in rhythm so they are
/// distinguishable by feel alone.
///
/// MANUAL TEST REQUIRED: vibration cannot be exercised in unit tests. Verify on
/// a physical device (emulators usually have no vibrator).
class VibrationFeedbackService implements PulseFeedbackOutput {
  bool _hasVibrator = false;

  Future<void> init() async {
    try {
      _hasVibrator = (await Vibration.hasVibrator()) == true;
    } catch (_) {
      _hasVibrator = false;
    }
  }

  @override
  Future<void> approachPulse() => _vibrate(duration: 40);

  @override
  Future<void> reached() => _pattern(const [0, 120, 80, 120]);

  @override
  Future<void> overTarget() => _pattern(const [0, 300, 140, 300]);

  Future<void> _vibrate({required int duration}) async {
    if (!_hasVibrator) return;
    try {
      await Vibration.vibrate(duration: duration);
    } catch (_) {}
  }

  Future<void> _pattern(List<int> pattern) async {
    if (!_hasVibrator) return;
    try {
      await Vibration.vibrate(pattern: pattern);
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}
