import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'controllers/preset_controller.dart';
import 'controllers/scale_controller.dart';
import 'controllers/settings_controller.dart';
import 'feedback/audio_feedback_service.dart';
import 'feedback/semantics_speech_output.dart';
import 'feedback/speech_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/connection_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/live_region_announcer.dart';

/// Root widget. Rebuilds the [MaterialApp] when settings change (high
/// contrast) and exposes the controllers via [AppScope]. Light/dark theming
/// and locale both follow the OS automatically, with no manual override:
/// [_resolveLocale] picks the first device-preferred language this app
/// supports, falling back to English. High
/// contrast stays a manual setting — Android's Flutter embedding does not
/// surface an OS high-contrast signal (`AccessibilityFeature.HIGH_CONTRAST`
/// is explicitly unsupported there), so it cannot be auto-detected the way
/// light/dark or locale can.
class NovaAccessScaleApp extends StatelessWidget {
  NovaAccessScaleApp({
    required this.settingsController,
    required this.presetController,
    required this.scaleController,
    required this.audioFeedback,
    required this.speechRouter,
    required this.semanticsSpeech,
    super.key,
  });

  final SettingsController settingsController;
  final PresetController presetController;
  final ScaleController scaleController;
  final AudioFeedbackService audioFeedback;
  final SpeechRouter speechRouter;

  /// The live-region channel. Held here so the app can mount its renderer over
  /// the whole tree — announcements can fire from any screen.
  final SemanticsSpeechOutput semanticsSpeech;

  /// Stable for the app's lifetime; registered with the Navigator below and
  /// consumed by the weighing screen to pause feedback when covered.
  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  // Computed once — none of the four palettes themselves depend on settings,
  // only which pair (plain vs. high-contrast) gets used below does.
  static final ThemeData _lightTheme = AppTheme.light();
  static final ThemeData _darkTheme = AppTheme.dark();
  static final ThemeData _highContrastLightTheme = AppTheme.highContrastLight();
  static final ThemeData _highContrastDarkTheme = AppTheme.highContrastDark();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settingsController: settingsController,
      presetController: presetController,
      scaleController: scaleController,
      audioFeedback: audioFeedback,
      speechRouter: speechRouter,
      semanticsSpeech: semanticsSpeech,
      routeObserver: routeObserver,
      child: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) {
          final settings = settingsController.settings;
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: settings.highContrast
                ? _highContrastLightTheme
                : _lightTheme,
            darkTheme: settings.highContrast
                ? _highContrastDarkTheme
                : _darkTheme,
            themeMode: ThemeMode.system,
            localeListResolutionCallback: _resolveLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            navigatorObservers: [routeObserver],
            // Mounted above every route so a spoken announcement can be
            // triggered from any screen and still reach the screen reader.
            builder: (context, child) =>
                LiveRegionAnnouncer(output: semanticsSpeech, child: child!),
            // Not const: _RootGate.build() pushes live settings (speech
            // output mode) into the speech router via a plain field read, not
            // an InheritedWidget. A const instance would be `identical()`
            // across rebuilds, and Element.updateChild skips calling build()
            // again for identical widgets — so those settings would freeze
            // after the first frame.
            home: _RootGate(),
          );
        },
      ),
    );
  }
}

/// Picks the first device-preferred language this app supports, or English if
/// none of the device's preferred languages are supported: the app follows the
/// device language by default and falls back to English.
/// `supportedLocales` is not relied on for the fallback itself since its
/// declaration order is alphabetical, not English-first.
Locale _resolveLocale(List<Locale>? deviceLocales, Iterable<Locale> supported) {
  final supportedCodes = supported.map((locale) => locale.languageCode).toSet();
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (supportedCodes.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('en');
}

/// Shows the connection screen until a scale is connected, then the home
/// (weighing) screen. Also pushes the resolved localization and speech language
/// into the scale controller, and the current accessibility state into the
/// speech router, whenever they change.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    scope.scaleController.setLocalization(
      AppLocalizations.of(context),
      Localizations.localeOf(context).languageCode,
    );

    // Speech routing depends on state that only exists in the widget tree.
    // MediaQuery and Directionality are build dependencies here, and this
    // subtree also rebuilds on settings changes, so switching TalkBack on or
    // off mid-session re-routes announcements without an app restart.
    scope.speechRouter
      ..mode = scope.settingsController.settings.speechOutputMode
      ..screenReaderActive = MediaQuery.of(context).accessibleNavigation;
    return ListenableBuilder(
      listenable: scope.scaleController,
      builder: (context, _) {
        return scope.scaleController.isConnected
            ? const HomeScreen()
            : const ConnectionScreen();
      },
    );
  }
}
