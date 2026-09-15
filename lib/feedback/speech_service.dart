import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'feedback_outputs.dart';

/// Spoken announcements via the platform text-to-speech engine.
///
/// This is the *fallback* speech channel, not the primary one. When a screen
/// reader is running, announcements go through the accessibility layer instead
/// so the user keeps their own voice, rate, and braille output; [SpeechRouter]
/// owns that decision and this class is one of its delegates.
///
/// IMPORTANT: on an *Android* device with no TTS engine installed, flutter_tts
/// can enter an endless re-init/re-queue loop on every speak() call, leading to
/// an ANR. We therefore probe [FlutterTts.getEngines] once at init and
/// short-circuit all calls when none is present. (Lesson carried over from
/// NovaAccessTag.)
///
/// getEngines is an Android-only API: on iOS it returns an empty list, which
/// must NOT be read as "no speech available". iOS always ships a system voice,
/// so we treat speech as available there without the engine probe.
///
/// MANUAL TEST REQUIRED: speech output cannot be exercised in unit tests
/// (no TTS engine on the host). Verify pronunciation and language switching on
/// a physical device.
class SpeechService implements SpeechOutput {
  SpeechService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  bool _available = false;
  String? _currentLocale;

  /// Maps an app language code to a TTS locale.
  static const Map<String, String> _localeByCode = {
    'en': 'en-US',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'it': 'it-IT',
  };

  @override
  bool get isAvailable => _available;

  Future<void> init() async {
    // The no-engine probe is an Android-only concern; elsewhere (iOS) the system
    // always provides a voice and getEngines would wrongly report none.
    if (defaultTargetPlatform != TargetPlatform.android) {
      // iOS: route speech through the shared audio session as "playback" so it
      // is audible even when the Ring/Silent switch is on or the screen is
      // locked (the default category is silenced by both). mixWithOthers lets
      // it coexist with the cadence tones; duckOthers lowers any background
      // media while announcing.
      try {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ]);
      } catch (_) {
        // Non-fatal: speech still works through the default session.
      }
      _available = true;
      return;
    }
    try {
      final engines = await _tts.getEngines;
      _available = engines is List && engines.isNotEmpty;
    } catch (_) {
      _available = false;
    }
  }

  @override
  Future<void> announce(String text, {required String languageCode}) async {
    if (!_available) return;
    final locale = _localeByCode[languageCode] ?? 'en-US';
    try {
      if (_currentLocale != locale) {
        await _tts.setLanguage(locale);
        _currentLocale = locale;
      }
      // Android's default queue mode flushes, so a new announcement replaces
      // any in-progress one — we always want the most recent value spoken.
      await _tts.speak(text);
    } catch (_) {
      // Speech is optional; swallow engine errors rather than break weighing.
    }
  }

  @override
  Future<void> stop() async {
    if (!_available) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
