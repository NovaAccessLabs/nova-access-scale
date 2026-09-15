/// How the app guides the user toward the target weight.
///
/// This is a global setting (per PRD). It does not change *when* feedback fires
/// (that is driven by the percentage-remaining cadence), only *which* channels
/// are used.
enum FeedbackMode {
  audio,
  vibration,
  audioVibration;

  bool get usesAudio =>
      this == FeedbackMode.audio || this == FeedbackMode.audioVibration;

  bool get usesVibration =>
      this == FeedbackMode.vibration || this == FeedbackMode.audioVibration;

  /// Parses a stored value by its [name], falling back to [audio] — the same
  /// default a first launch gets, so a corrupt store never silently turns on a
  /// channel the user did not ask for.
  static FeedbackMode fromName(String? name) {
    return FeedbackMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => FeedbackMode.audio,
    );
  }
}
