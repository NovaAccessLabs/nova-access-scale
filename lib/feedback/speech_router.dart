import '../models/speech_output_mode.dart';
import 'feedback_outputs.dart';

/// Decides *which voice* speaks an announcement, and is the only place that
/// decision lives.
///
/// Blind-first means screen-reader-first: when a screen reader is running, the
/// announcement goes through the accessibility layer and the app's own TTS
/// stays quiet, so the user hears their own voice at their own rate and a
/// braille display gets the text. When no screen reader is running, app TTS
/// speaks instead — a low-vision user on magnification must never be left in
/// silence.
///
/// | mode          | screen reader active   | no screen reader |
/// |---------------|------------------------|------------------|
/// | screenReader  | accessibility layer    | app TTS          |
/// | appVoice      | app TTS                | app TTS          |
/// | both          | accessibility + TTS    | app TTS          |
///
/// [FeedbackCoordinator] holds this as a plain [SpeechOutput] and is unaware of
/// the routing; the app pushes [mode] and [screenReaderActive] in from the
/// widget tree, where MediaQuery makes them observable (so toggling TalkBack
/// mid-session re-routes without a restart).
///
/// The accessibility route is a live region, not an announcement event — see
/// SemanticsSpeechOutput for why, and note that it reports itself unavailable
/// unless its renderer is mounted, so this router falls back to speaking rather
/// than going quiet.
class SpeechRouter implements SpeechOutput {
  SpeechRouter({required SpeechOutput tts, required SpeechOutput semantics})
    : _tts = tts,
      _semantics = semantics;

  final SpeechOutput _tts;
  final SpeechOutput _semantics;

  /// The user's speech-output preference. Defaults to screen-reader-first.
  SpeechOutputMode mode = SpeechOutputMode.screenReader;

  /// Whether the platform reports a screen reader as active. Sourced from
  /// `MediaQuery.accessibleNavigation`.
  bool screenReaderActive = false;

  /// Whether the accessibility layer is the route for the current state.
  bool get _usesSemantics =>
      screenReaderActive &&
      mode != SpeechOutputMode.appVoice &&
      _semantics.isAvailable;

  /// Whether app-owned TTS speaks in the current state. It is suppressed in
  /// exactly one case: [SpeechOutputMode.screenReader] while the accessibility
  /// layer is actually carrying the announcement — speaking then would talk
  /// over the user's own voice. If that route is unavailable, TTS speaks, so no
  /// state leaves the user in silence.
  bool get _usesTts => mode != SpeechOutputMode.screenReader || !_usesSemantics;

  /// True when *some* route can speak. The accessibility layer needs no engine,
  /// so a device with no TTS engine installed still announces to a screen
  /// reader user — without this, the coordinator would drop the announcement.
  @override
  bool get isAvailable => _usesSemantics || _tts.isAvailable;

  @override
  Future<void> announce(String text, {required String languageCode}) async {
    // Both routes are started before awaiting, so "both" mode does not stagger
    // the two voices by a round-trip.
    final pending = <Future<void>>[
      if (_usesSemantics) _semantics.announce(text, languageCode: languageCode),
      if (_usesTts) _tts.announce(text, languageCode: languageCode),
    ];
    try {
      await Future.wait(pending);
    } catch (_) {
      // Speech is optional; a failing accessibility channel or TTS engine must
      // not break weighing. The coordinator calls this without awaiting, so an
      // escaping error would surface as an unhandled async exception.
    }
  }

  /// Stops app-owned speech and clears the accessibility route.
  ///
  /// Speech already handed to the screen reader cannot be retracted, but the
  /// live region must still be cleared: its label persists in the semantics
  /// tree, so a stale "Over target by 0.3 grams" was still the first thing a
  /// TalkBack user met on the connection screen after disconnecting
  /// (found on-device 2026-08-11).
  @override
  Future<void> stop() async {
    await Future.wait([_tts.stop(), _semantics.stop()]);
  }
}
