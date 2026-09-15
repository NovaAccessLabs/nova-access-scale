import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/app_scope.dart';
import 'package:nova_access_scale/controllers/preset_controller.dart';
import 'package:nova_access_scale/controllers/scale_controller.dart';
import 'package:nova_access_scale/controllers/settings_controller.dart';
import 'package:nova_access_scale/feedback/audio_feedback_service.dart';
import 'package:nova_access_scale/feedback/feedback_coordinator.dart';
import 'package:nova_access_scale/feedback/feedback_outputs.dart';
import 'package:nova_access_scale/feedback/semantics_speech_output.dart';
import 'package:nova_access_scale/feedback/speech_router.dart';
import 'package:nova_access_scale/l10n/generated/app_localizations.dart';
import 'package:nova_access_scale/models/speech_output_mode.dart';
import 'package:nova_access_scale/repositories/preset_repository.dart';
import 'package:nova_access_scale/repositories/settings_repository.dart';
import 'package:nova_access_scale/scale/scale_ble_service.dart';
import 'package:nova_access_scale/scale/scale_protocol_registry.dart';
import 'package:nova_access_scale/screens/settings_screen.dart';
import 'package:nova_access_scale/theme/app_theme.dart';
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

/// Pumps the settings screen with [accessibleNavigation] forced, standing in
/// for the OS reporting a screen reader as active.
Future<SettingsController> _pumpSettings(
  WidgetTester tester, {
  required bool accessibleNavigation,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);
  final settings = SettingsController(settingsRepo);
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

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(accessibleNavigation: accessibleNavigation),
        child: AppScope(
          scaleController: scale,
          settingsController: settings,
          presetController: presets,
          audioFeedback: AudioFeedbackService(),
          speechRouter: SpeechRouter(
            tts: _NoopSpeech(),
            semantics: _NoopSpeech(),
          ),
          semanticsSpeech: SemanticsSpeechOutput(),
          routeObserver: RouteObserver<ModalRoute<void>>(),
          child: const SettingsScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  return settings;
}

void main() {
  group('speech output setting', () {
    testWidgets('defaults to routing through the screen reader', (
      tester,
    ) async {
      final settings = await _pumpSettings(tester, accessibleNavigation: true);

      expect(settings.settings.speechOutputMode, SpeechOutputMode.screenReader);
      await tester.scrollUntilVisible(find.text('Speech output'), 200);
      expect(find.text('Speech output'), findsOneWidget);
    });

    testWidgets('lets the user switch to the app voice', (tester) async {
      final settings = await _pumpSettings(tester, accessibleNavigation: true);
      await tester.scrollUntilVisible(find.text('App voice'), 200);

      await tester.tap(find.text('App voice'));
      await tester.pumpAndSettle();

      expect(settings.settings.speechOutputMode, SpeechOutputMode.appVoice);
    });

    testWidgets('hides the choice when announcements are off', (tester) async {
      final settings = await _pumpSettings(tester, accessibleNavigation: true);
      await settings.setSpeechEnabled(false);
      await tester.pumpAndSettle();

      // Nothing will be spoken, so a voice choice would be misleading.
      expect(find.text('Speech output'), findsNothing);
    });

    testWidgets('never offers "Both" — talking over an active screen reader '
        'has no good reason to exist, and off, every mode already collapses '
        'to app voice', (tester) async {
      await _pumpSettings(tester, accessibleNavigation: true);
      await tester.scrollUntilVisible(find.text('Speech output'), 200);
      expect(find.text('Both'), findsNothing);

      await _pumpSettings(tester, accessibleNavigation: false);
      expect(find.text('Both'), findsNothing);
    });

    testWidgets(
      'shows nothing below "Spoken announcements" when no screen reader is '
      'active, since screen reader vs. app voice is not a live choice then '
      'and stating the automatic outcome would be self-evident chrome',
      (tester) async {
        await _pumpSettings(tester, accessibleNavigation: false);

        expect(find.text('Speech output'), findsNothing);
        expect(find.text('Screen reader voice'), findsNothing);
        expect(find.text('App voice'), findsNothing);
      },
    );
  });

  group('high contrast setting', () {
    testWidgets('is off by default, exposed as a switch (not colour alone)', (
      tester,
    ) async {
      final settings = await _pumpSettings(tester, accessibleNavigation: true);

      expect(settings.settings.highContrast, isFalse);
      final tile = find.widgetWithText(SwitchListTile, 'High contrast');
      expect(tile, findsOneWidget);
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    });

    testWidgets('tapping the row toggles the controller', (tester) async {
      final settings = await _pumpSettings(tester, accessibleNavigation: true);

      await tester.tap(find.widgetWithText(SwitchListTile, 'High contrast'));
      await tester.pumpAndSettle();

      expect(settings.settings.highContrast, isTrue);
    });
  });

  group('removed manual controls stay removed', () {
    // Regression guard: the old 3-preset theme picker, Text size, and the
    // Language picker were deliberately removed — theme/locale now follow
    // the OS automatically, high contrast is the one manual toggle left
    // (now under its own "Appearance" heading, so that text is expected).
    testWidgets('no old theme picker, text size, or language picker', (
      tester,
    ) async {
      await _pumpSettings(tester, accessibleNavigation: true);

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Text size'), findsNothing);
      expect(find.text('Language'), findsNothing);
      expect(find.text('System default'), findsNothing);
      expect(find.text('White on black'), findsNothing);
      expect(find.text('Black on yellow'), findsNothing);
    });
  });
}
