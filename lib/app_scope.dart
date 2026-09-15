import 'package:flutter/widgets.dart';

import 'controllers/preset_controller.dart';
import 'controllers/scale_controller.dart';
import 'controllers/settings_controller.dart';
import 'feedback/audio_feedback_service.dart';
import 'feedback/semantics_speech_output.dart';
import 'feedback/speech_router.dart';

/// Provides the app's controllers to the widget tree without a third-party
/// state-management package — `ChangeNotifier` only. The
/// controllers are stable for the app's lifetime, so this never needs to
/// notify; widgets listen to the individual controllers with [ListenableBuilder].
class AppScope extends InheritedWidget {
  const AppScope({
    required this.scaleController,
    required this.settingsController,
    required this.presetController,
    required this.audioFeedback,
    required this.speechRouter,
    required this.semanticsSpeech,
    required this.routeObserver,
    required super.child,
    super.key,
  });

  final ScaleController scaleController;
  final SettingsController settingsController;
  final PresetController presetController;

  /// The synthesized-earcon player, exposed so Settings can play a short
  /// confirmation tone when the user selects a sound-capable feedback mode.
  final AudioFeedbackService audioFeedback;

  /// Routes announcements between the user's screen reader and the app's own
  /// voice. Exposed so the widget tree can keep it in sync with the platform's
  /// accessibility state, which is only observable from a BuildContext.
  final SpeechRouter speechRouter;

  /// Screen-reader announcements for UI events that are not weighing feedback
  /// (a scan result, a validation error). Goes straight to the live region:
  /// these are screen-reader messages, so they are not gated by the speech
  /// settings and are simply inert when no screen reader is running.
  final SemanticsSpeechOutput semanticsSpeech;

  /// Observes route pushes so the weighing screen can pause feedback while
  /// another screen is open on top of it.
  final RouteObserver<ModalRoute<void>> routeObserver;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
