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
import 'package:nova_access_scale/repositories/preset_repository.dart';
import 'package:nova_access_scale/repositories/settings_repository.dart';
import 'package:nova_access_scale/scale/scale_ble_service.dart';
import 'package:nova_access_scale/scale/scale_protocol.dart';
import 'package:nova_access_scale/scale/scale_protocol_registry.dart';
import 'package:nova_access_scale/screens/connection_screen.dart';
import 'package:nova_access_scale/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  // Regression: ConnectionScreen assigned its `late final` controller in
  // didChangeDependencies, which Flutter calls again on a theme/locale change
  // while the screen is mounted — the second assignment threw
  // LateInitializationError. A locale change must not crash the screen.
  testWidgets('ConnectionScreen survives a repeated didChangeDependencies', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsRepo = SettingsRepository(prefs);
    final settings = SettingsController(settingsRepo);
    await settings.setDemoMode(true); // keep startScan off the BLE plugin path
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

    Widget appWith(Locale locale) => MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppScope(
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
        child: const ConnectionScreen(),
      ),
    );

    await tester.pumpWidget(appWith(const Locale('en')));
    await tester.pump(); // runs the post-frame startScan (demo path, no BLE)
    expect(find.byType(ConnectionScreen), findsOneWidget);

    // Change the locale -> Localizations changes -> the same ConnectionScreen
    // State gets didChangeDependencies a second time.
    await tester.pumpWidget(appWith(const Locale('fr')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ConnectionScreen), findsOneWidget);
  });

  testWidgets(
    'AppBar has no actions — Settings moved to the end of the body instead, '
    'same place and reasoning as on Home',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsRepo = SettingsRepository(prefs);
      final settings = SettingsController(settingsRepo);
      await settings.setDemoMode(true);
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
          home: AppScope(
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
            child: const ConnectionScreen(),
          ),
        ),
      );
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, anyOf(isNull, isEmpty));

      final column = tester.widget<ListView>(find.byType(ListView));
      final children = column.childrenDelegate as SliverChildListDelegate;
      final lastRealChild = children.children.lastWhere((w) => w is! SizedBox);
      expect(
        find.descendant(
          of: find.byWidget(lastRealChild),
          matching: find.byIcon(Icons.settings_outlined),
        ),
        findsOneWidget,
      );
    },
  );

  // Regression: the error banner and "Connecting…" indicator used to rely on
  // Semantics(liveRegion: true) on a freshly-appearing node. This screen's own
  // device-count fix already established that pattern is not trusted here —
  // both now go through an explicit semanticsSpeech.announce() instead, the
  // same mechanism _announceDeviceCount uses.
  testWidgets(
    'announces a connection error through semanticsSpeech, not just the '
    'visual banner',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsRepo = SettingsRepository(prefs);
      final settings = SettingsController(settingsRepo);
      await settings.setDemoMode(true); // keep startScan off the BLE path
      final presets = PresetController(PresetRepository(prefs));
      final registry = ScaleProtocolRegistry([]); // nothing matches -> error
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
      final semanticsSpeech = SemanticsSpeechOutput()..attachRenderer();

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
          home: AppScope(
            scaleController: scale,
            settingsController: settings,
            presetController: presets,
            audioFeedback: AudioFeedbackService(),
            speechRouter: SpeechRouter(
              tts: _NoopSpeech(),
              semantics: _NoopSpeech(),
            ),
            semanticsSpeech: semanticsSpeech,
            routeObserver: RouteObserver<ModalRoute<void>>(),
            child: const ConnectionScreen(),
          ),
        ),
      );
      await tester.pump();

      // A device name the empty registry cannot match -> the synchronous
      // "unsupported" error path, no real BLE plugin involved.
      await scale.connect(
        const ScaleDevice(id: 'unmatched', name: 'unmatched'),
      );
      await tester.pump();

      expect(find.text('Could not connect. Please try again.'), findsOneWidget);
      expect(
        semanticsSpeech.message.value,
        'Could not connect. Please try again.',
      );
    },
  );

  // Regression: _announceConnecting/_announceError call semanticsSpeech
  // directly rather than going through SpeechRouter, so they need their own
  // copy of the cleanup SpeechRouter already needed once before — a stale
  // "Over target by 0.3 grams" was still the first thing a TalkBack user met
  // on this screen after disconnecting (2026-08-11). Confirmed live on
  // device too: without this, "Connecting…" outlived ConnectionScreen and
  // was still in the semantics tree on Home.
  testWidgets(
    'clears the live region on dispose, so a stale error or "Connecting…" '
    "does not outlive this screen and greet the user on whatever's next",
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsRepo = SettingsRepository(prefs);
      final settings = SettingsController(settingsRepo);
      await settings.setDemoMode(true);
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
      final semanticsSpeech = SemanticsSpeechOutput()..attachRenderer();

      Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppScope(
          scaleController: scale,
          settingsController: settings,
          presetController: presets,
          audioFeedback: AudioFeedbackService(),
          speechRouter: SpeechRouter(
            tts: _NoopSpeech(),
            semantics: _NoopSpeech(),
          ),
          semanticsSpeech: semanticsSpeech,
          routeObserver: RouteObserver<ModalRoute<void>>(),
          child: child,
        ),
      );

      await tester.pumpWidget(appWith(const ConnectionScreen()));
      await tester.pump();

      await scale.connect(
        const ScaleDevice(id: 'unmatched', name: 'unmatched'),
      );
      await tester.pump();
      expect(semanticsSpeech.message.value, isNotNull);

      // Replace ConnectionScreen with something else — its State.dispose runs.
      await tester.pumpWidget(appWith(const SizedBox.shrink()));
      await tester.pump();

      expect(semanticsSpeech.message.value, isNull);
    },
  );

  // No dedicated widget test for the "Connecting…" announcement:
  // _announceConnecting is the same guard-and-announce shape as
  // _announceError above (proven passing), just keyed on the connecting
  // transition instead of the error key, and driving it through a real
  // MockScaleProtocol.connect() leaves a periodic timer that
  // ScaleController.dispose()'s pre-existing fire-and-forget teardown chain
  // does not reliably clear before flutter_test's pending-timer check runs
  // — a teardown-plumbing issue unrelated to this change. Verified live on
  // device instead.
}
