import 'package:flutter/foundation.dart';

import 'feedback_outputs.dart';

/// Speech delivered through the platform accessibility layer, as a **live
/// region** the screen reader reads on its own.
///
/// This deliberately does NOT use `SemanticsService.announce` /
/// `sendAnnouncement`. Announcement events are deprecated as of Android 16 and
/// this app targets SDK 36; on a Pixel 4a 5G with TalkBack they were verified
/// **silent** (2026-08-11). Because the router suppresses the app's own TTS
/// whenever it believes the accessibility layer is carrying the announcement,
/// that left a blind user with no speech at all — the exact failure this
/// app must never have. A live region was
/// verified spoken by TalkBack on the same device, so that is the mechanism.
///
/// The text is published here; [LiveRegionAnnouncer] renders it into the
/// semantics tree. Nothing can be spoken without a mounted renderer, so
/// [isAvailable] reports whether one is attached and [SpeechRouter] falls back
/// to app TTS when none is — silence is never an outcome.
///
/// One-off messages only (grams remaining on a pause, target reached).
/// Continuously changing values must not come through here: see home_screen.dart,
/// where the live readout is deliberately not a live region.
class SemanticsSpeechOutput implements SpeechOutput {
  /// Zero-width space. A live region is only re-read when its label actually
  /// changes, so an identical consecutive message would be silent. Alternating
  /// this invisible, unspoken suffix makes the label differ without changing
  /// what the user hears.
  static const String _nonce = '​';

  final ValueNotifier<String?> _message = ValueNotifier<String?>(null);

  /// The current announcement, watched by [LiveRegionAnnouncer].
  ValueListenable<String?> get message => _message;

  int _renderers = 0;

  /// Called by [LiveRegionAnnouncer] when it mounts / unmounts.
  void attachRenderer() => _renderers++;
  void detachRenderer() {
    if (_renderers > 0) _renderers--;
  }

  @override
  bool get isAvailable => _renderers > 0;

  @override
  Future<void> announce(String text, {required String languageCode}) async {
    // languageCode is intentionally unused: the screen reader speaks in the
    // user's own configured voice and language, which we must not override.
    if (_renderers == 0) return;
    final current = _message.value;
    final bare = current?.replaceAll(_nonce, '');
    if (bare != text) {
      _message.value = text;
    } else {
      // Same text as last time — toggle the nonce so the raw value actually
      // changes from `current`, not just from `bare`. Stripping the nonce
      // before comparing (above) is only for recognising a repeat; flipping
      // based on whether `current` *itself* carries the nonce is what makes
      // this alternate on every repeat instead of only the first one — get
      // this backwards and the value stops changing (and TalkBack stops
      // re-announcing) from the third identical announcement onward, since
      // stripping-then-reappending the same nonce reproduces `current` as-is.
      _message.value = current!.endsWith(_nonce) ? text : '$text$_nonce';
    }
  }

  /// Clears the live region. There is no way to retract speech already handed
  /// to the screen reader — this only stops the text being re-read.
  @override
  Future<void> stop() async => _message.value = null;

  void dispose() => _message.dispose();
}
