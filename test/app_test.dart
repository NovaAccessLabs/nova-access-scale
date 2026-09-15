import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/app.dart';
import 'package:nova_access_scale/controllers/preset_controller.dart';
import 'package:nova_access_scale/controllers/scale_controller.dart';
import 'package:nova_access_scale/controllers/settings_controller.dart';
import 'package:nova_access_scale/feedback/audio_feedback_service.dart';
import 'package:nova_access_scale/feedback/feedback_coordinator.dart';
import 'package:nova_access_scale/feedback/feedback_outputs.dart';
import 'package:nova_access_scale/feedback/semantics_speech_output.dart';
import 'package:nova_access_scale/feedback/speech_router.dart';
import 'package:nova_access_scale/models/speech_output_mode.dart';
import 'package:nova_access_scale/repositories/preset_repository.dart';
import 'package:nova_access_scale/repositories/settings_repository.dart';
import 'package:nova_access_scale/scale/scale_ble_service.dart';
import 'package:nova_access_scale/scale/scale_protocol_registry.dart';
import 'package:nova_access_scale/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lightweight no-op feedback channels so the controller graph can be built
// without touching audio/vibration/TTS plugins.
class _NoopPulse implements PulseFeedbackOutput {
  @override
  Future<void> approachPulse() async {}
  @override
  Future<void> reached() async {}
  @override
  Future<void> overTarget() async {}
}

class _NoopSpeech implements SpeechOutput {
  @override
  bool get isAvailable => false;
  @override
  Future<void> announce(String text, {required String languageCode}) async {}
  @override
  Future<void> stop() async {}
}

/// Builds the real app and pumps one frame. Demo mode is forced on: no scale
/// is connected, so the root gate shows ConnectionScreen, whose initState
/// triggers a scan — demo mode makes that scan take its early-return path
/// instead of reaching the (unmocked) BLE platform channel, which would
/// otherwise leave a pending command-queue timer when the test tears down.
Future<(SettingsController settings, SpeechRouter speechRouter)> _pumpApp(
  WidgetTester tester, {
  required bool highContrast,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);
  final settings = SettingsController(settingsRepo);
  await settings.setDemoMode(true);
  await settings.setHighContrast(highContrast);
  final presets = PresetController(PresetRepository(prefs));
  final registry = ScaleProtocolRegistry([]);
  final scale = ScaleController(
    settingsController: settings,
    settingsRepository: settingsRepo,
    bleService: ScaleBleService(registry),
    registry: registry,
    coordinator: FeedbackCoordinator(
      audio: _NoopPulse(),
      haptic: _NoopPulse(),
      speech: _NoopSpeech(),
    ),
  );
  addTearDown(scale.dispose);
  final speechRouter = SpeechRouter(
    tts: _NoopSpeech(),
    semantics: _NoopSpeech(),
  );

  await tester.pumpWidget(
    NovaAccessScaleApp(
      settingsController: settings,
      presetController: presets,
      scaleController: scale,
      audioFeedback: AudioFeedbackService(),
      speechRouter: speechRouter,
      semanticsSpeech: SemanticsSpeechOutput(),
    ),
  );
  await tester.pump();

  return (settings, speechRouter);
}

Future<MaterialApp> _pumpAppForTheme(
  WidgetTester tester, {
  required bool highContrast,
}) async {
  await _pumpApp(tester, highContrast: highContrast);
  return tester.widget<MaterialApp>(find.byType(MaterialApp));
}

void main() {
  // Compare palette + brightness per slot rather than whole-ThemeData
  // equality: AppTheme.build() uses WidgetStateProperty.resolveWith for the
  // switch theme, and closures have identity-only equality, so two
  // independently-built ThemeData instances are never `==` even with
  // identical colors.

  testWidgets('light/dark follows the OS; high contrast off by default', (
    tester,
  ) async {
    final materialApp = await _pumpAppForTheme(tester, highContrast: false);
    expect(materialApp.theme!.extension<BrandColors>(), BrandColors.light);
    expect(materialApp.theme!.brightness, Brightness.light);
    expect(materialApp.darkTheme!.extension<BrandColors>(), BrandColors.dark);
    expect(materialApp.darkTheme!.brightness, Brightness.dark);
    expect(materialApp.themeMode, ThemeMode.system);
  });

  testWidgets(
    'high contrast on swaps both slots to the high-contrast palette',
    (tester) async {
      final materialApp = await _pumpAppForTheme(tester, highContrast: true);
      expect(
        materialApp.theme!.extension<BrandColors>(),
        BrandColors.hcBlackOnYellow,
      );
      expect(materialApp.theme!.brightness, Brightness.light);
      expect(
        materialApp.darkTheme!.extension<BrandColors>(),
        BrandColors.hcWhiteOnBlack,
      );
      expect(materialApp.darkTheme!.brightness, Brightness.dark);
      expect(materialApp.themeMode, ThemeMode.system);
    },
  );

  testWidgets(
    'locale: uses a supported device language, else falls back to English '
    '— no in-app language picker',
    (tester) async {
      final materialApp = await _pumpAppForTheme(tester, highContrast: false);
      final resolve = materialApp.localeListResolutionCallback!;
      final supported = materialApp.supportedLocales;

      // Exact supported match, first preference.
      expect(resolve([const Locale('de')], supported), const Locale('de'));
      // Supported language with a region subtag still matches by language.
      expect(
        resolve([const Locale('en', 'GB')], supported),
        const Locale('en'),
      );
      // First preference unsupported, second is — the resolver should not
      // just look at index 0.
      expect(
        resolve([const Locale('ja'), const Locale('fr')], supported),
        const Locale('fr'),
      );
      // Nothing supported anywhere in the list — falls back to English.
      expect(
        resolve([const Locale('ja'), const Locale('ko')], supported),
        const Locale('en'),
      );
      // No device locales reported at all.
      expect(resolve(null, supported), const Locale('en'));
    },
  );

  testWidgets('changing speech output after launch still reaches the router '
      '(regression: home must not be const, or Element.updateChild skips '
      'rebuilding _RootGate and this update is dropped)', (tester) async {
    final (settings, speechRouter) = await _pumpApp(
      tester,
      highContrast: false,
    );
    expect(speechRouter.mode, SpeechOutputMode.screenReader);

    await settings.setSpeechOutputMode(SpeechOutputMode.appVoice);
    await tester.pump();

    expect(speechRouter.mode, SpeechOutputMode.appVoice);
  });
}
