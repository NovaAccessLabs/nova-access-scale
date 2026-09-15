import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/preset_controller.dart';
import 'controllers/scale_controller.dart';
import 'controllers/settings_controller.dart';
import 'feedback/audio_feedback_service.dart';
import 'feedback/feedback_coordinator.dart';
import 'feedback/semantics_speech_output.dart';
import 'feedback/speech_router.dart';
import 'feedback/speech_service.dart';
import 'feedback/vibration_feedback_service.dart';
import 'repositories/preset_repository.dart';
import 'repositories/settings_repository.dart';
import 'scale/scale_ble_service.dart';
import 'scale/scale_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(prefs);
  final presetRepository = PresetRepository(prefs);

  final settingsController = SettingsController(settingsRepository);
  final presetController = PresetController(presetRepository);

  // Feedback output channels. Each init() is defensive — a missing engine or
  // vibrator simply disables that channel rather than failing startup. They are
  // warmed up AFTER runApp (below) so initialization never blocks the first
  // frame; until ready, each channel is a harmless no-op.
  final audio = AudioFeedbackService();
  final haptic = VibrationFeedbackService();
  final speech = SpeechService();

  // Announcements go through the router, not the TTS engine directly: when a
  // screen reader is active the user's own voice speaks them (and a braille
  // display gets them), with app TTS as the fallback. The widget tree keeps the
  // router's accessibility state and mode current.
  final semanticsSpeech = SemanticsSpeechOutput();
  final speechRouter = SpeechRouter(tts: speech, semantics: semanticsSpeech);

  final coordinator = FeedbackCoordinator(
    audio: audio,
    haptic: haptic,
    speech: speechRouter,
  );

  final registry = buildScaleRegistry();
  final bleService = ScaleBleService(registry);

  final scaleController = ScaleController(
    settingsController: settingsController,
    settingsRepository: settingsRepository,
    bleService: bleService,
    registry: registry,
    coordinator: coordinator,
  )..init();

  runApp(
    NovaAccessScaleApp(
      settingsController: settingsController,
      presetController: presetController,
      scaleController: scaleController,
      audioFeedback: audio,
      speechRouter: speechRouter,
      semanticsSpeech: semanticsSpeech,
    ),
  );

  // Warm up the feedback channels in the background, after the first frame.
  unawaited(Future.wait([audio.init(), haptic.init(), speech.init()]));
}
