// Output channels used to guide the user. Defined as interfaces so the
// feedback coordinator can be unit-tested with fakes, and so adding a channel
// (or swapping a backend) does not touch the coordinator's decision logic.

/// A non-verbal cue channel (sound or haptics). The three cues mirror the
/// feedback states the user cares about.
abstract interface class PulseFeedbackOutput {
  /// A single approach pulse, emitted on the cadence while below target.
  Future<void> approachPulse();

  /// Distinct success cue when the target is reached.
  Future<void> reached();

  /// Distinct warning cue when over the target.
  Future<void> overTarget();
}

/// Spoken output. Announcements are always provided as already-localized text
/// (the coordinator builds them from AppLocalizations), so this layer stays
/// free of localization concerns and only needs the language code to pick a
/// matching TTS voice.
abstract interface class SpeechOutput {
  /// Whether a usable TTS engine is present. When false, [announce] is a no-op.
  bool get isAvailable;

  Future<void> announce(String text, {required String languageCode});

  Future<void> stop();
}
