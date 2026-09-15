/// Which voice speaks the app's announcements.
///
/// Blind-first means screen-reader-first: the user's own screen reader carries their chosen
/// voice, rate, language, and verbosity, and it is the only path that reaches a
/// braille display. The app's own TTS is a fallback, not the primary channel.
///
/// This is a global setting (like [FeedbackMode]). It selects the *route*, not
/// whether announcements happen at all — that stays [AppSettings.speechEnabled].
/// Non-speech cues (tones, vibration) are unaffected by this setting.
enum SpeechOutputMode {
  /// Default. Announce through the platform accessibility layer whenever a
  /// screen reader is active; use the app's own voice only when none is.
  ///
  /// The fallback is deliberate: a low-vision user on magnification with the
  /// screen reader off must not be left in silence. "Screen reader" therefore
  /// means "never talk *over* the screen reader", not "never speak".
  screenReader,

  /// Always use the app's own voice, even while a screen reader is running.
  /// For users who prefer this app's phrasing/voice to their screen reader's.
  appVoice,

  /// Announce through the accessibility layer *and* speak with the app's voice.
  /// The only mode in which both are heard at once; strictly opt-in.
  both;

  /// Parses a stored value by its [name], falling back to [screenReader].
  static SpeechOutputMode fromName(String? name) {
    return SpeechOutputMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => SpeechOutputMode.screenReader,
    );
  }
}
