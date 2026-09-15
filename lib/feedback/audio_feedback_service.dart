import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'feedback_outputs.dart';
import 'tone_synthesizer.dart';

/// Plays the synthesized feedback earcons with low latency.
///
/// Each cue gets its own pre-loaded [AudioPlayer] so replaying is just a
/// stop + resume (no re-decoding). The WAV bytes are synthesized in memory by
/// [ToneSynthesizer] — nothing is bundled as an asset.
///
/// MANUAL TEST REQUIRED: audio playback cannot be exercised in unit tests.
/// Verify the three cues are audible and distinct on a physical device.
class AudioFeedbackService implements PulseFeedbackOutput {
  AudioFeedbackService({this.synthesizer = const ToneSynthesizer()});

  final ToneSynthesizer synthesizer;

  final AudioPlayer _approachPlayer = AudioPlayer();
  final AudioPlayer _reachedPlayer = AudioPlayer();
  final AudioPlayer _overPlayer = AudioPlayer();

  bool _ready = false;

  Future<void> init() async {
    // iOS: play the earcons as "playback" audio so they sound with the
    // Ring/Silent switch on, and mixWithOthers so the tones and the spoken
    // announcements coexist instead of interrupting one another. (Android keeps
    // its default context.)
    if (defaultTargetPlatform != TargetPlatform.android) {
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      } catch (_) {
        // Non-fatal: tones still play through the default session.
      }
    }
    await _prepare(
      _approachPlayer,
      synthesizer.synthesize(FeedbackTones.approach),
    );
    await _prepare(
      _reachedPlayer,
      synthesizer.synthesize(FeedbackTones.reached),
    );
    await _prepare(_overPlayer, synthesizer.synthesize(FeedbackTones.over));
    _ready = true;
  }

  Future<void> _prepare(AudioPlayer player, Uint8List wav) async {
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(BytesSource(wav, mimeType: 'audio/wav'));
  }

  @override
  Future<void> approachPulse() => _play(_approachPlayer);

  @override
  Future<void> reached() => _play(_reachedPlayer);

  @override
  Future<void> overTarget() => _play(_overPlayer);

  Future<void> _play(AudioPlayer player) async {
    if (!_ready) return;
    try {
      await player.stop();
      await player.resume();
    } catch (_) {
      // Audio is supplemental; never let a playback hiccup break weighing.
    }
  }

  Future<void> dispose() async {
    await _approachPlayer.dispose();
    await _reachedPlayer.dispose();
    await _overPlayer.dispose();
  }
}
