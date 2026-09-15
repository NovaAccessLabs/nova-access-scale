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
import 'package:nova_access_scale/scale/scale_protocol_registry.dart';
import 'package:nova_access_scale/screens/home_screen.dart';
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

Future<void> _pumpHome(WidgetTester tester) async {
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
  // No init() -> targetWeight is null.

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
        child: const HomeScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows "No target set" exactly once when no target is set', (
    tester,
  ) async {
    await _pumpHome(tester);

    // Previously appeared twice (target line + status line both fell back).
    expect(find.text('No target set'), findsOneWidget);
    // The live weight readout is exposed to screen readers in grams.
    expect(find.bySemanticsLabel('0.0 grams'), findsOneWidget);
  });

  testWidgets(
    'AppBar has no actions — manual disconnect was removed, and Settings '
    'moved to the end of the body instead of the AppBar (rarely used, so it '
    'should not be the first thing a screen reader swipes past)',
    (tester) async {
      await _pumpHome(tester);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, anyOf(isNull, isEmpty));
      expect(find.byIcon(Icons.bluetooth_disabled), findsNothing);
      expect(find.byTooltip('Disconnect'), findsNothing);

      // Settings is reachable, just not from the AppBar: it's the last
      // widget in the body's scrollable list, after every weighing action.
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

  testWidgets(
    'Tare exposes its hint through Semantics.hint, not a bare Tooltip '
    '(Tooltip.message is only folded into the announced content when the '
    'node has no label of its own; this button already has one, so a '
    'Tooltip would silently drop the hint on normal TalkBack focus — '
    'confirmed against AccessibilityBridge.createAccessibilityNodeInfo)',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpHome(tester);

      final node = tester.getSemantics(find.text('Tare'));
      final data = node.getSemanticsData();
      expect(data.label, 'Tare');
      expect(data.hint, 'Reset the scale to zero');

      handle.dispose();
    },
  );
}
