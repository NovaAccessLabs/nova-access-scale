import 'package:flutter/foundation.dart';

import 'feedback_mode.dart';
import 'speech_output_mode.dart';

/// User-configurable settings.
///
/// Persisted as JSON via SettingsRepository. All fields have safe defaults so a
/// first launch — or a partially corrupt store — yields a usable configuration.
@immutable
class AppSettings {
  const AppSettings({
    this.feedbackMode = FeedbackMode.audio,
    this.speechEnabled = true,
    this.speechOutputMode = SpeechOutputMode.screenReader,
    this.highContrast = false,
    this.autoReconnect = true,
    this.demoMode = false,
  });

  /// Which feedback channels guide the user (sound, vibration, or both).
  final FeedbackMode feedbackMode;

  /// Whether spoken grams-remaining announcements are enabled.
  final bool speechEnabled;

  /// Which voice speaks those announcements: the user's screen reader (default,
  /// with the app's voice as fallback when none is running), the app's own
  /// voice, or both.
  final SpeechOutputMode speechOutputMode;

  /// Whether to use the high-contrast palette (white-on-black in dark mode,
  /// black-on-yellow in light mode) instead of the standard theme. Manual —
  /// Android's Flutter embedding does not surface an OS high-contrast signal
  /// (`AccessibilityFeature.HIGH_CONTRAST` is explicitly unsupported there).
  final bool highContrast;

  /// Whether to reconnect to the last scale on launch.
  final bool autoReconnect;

  /// Whether to use the simulated scale instead of real BLE hardware.
  final bool demoMode;

  AppSettings copyWith({
    FeedbackMode? feedbackMode,
    bool? speechEnabled,
    SpeechOutputMode? speechOutputMode,
    bool? highContrast,
    bool? autoReconnect,
    bool? demoMode,
  }) {
    return AppSettings(
      feedbackMode: feedbackMode ?? this.feedbackMode,
      speechEnabled: speechEnabled ?? this.speechEnabled,
      speechOutputMode: speechOutputMode ?? this.speechOutputMode,
      highContrast: highContrast ?? this.highContrast,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      demoMode: demoMode ?? this.demoMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'feedbackMode': feedbackMode.name,
    'speechEnabled': speechEnabled,
    'speechOutputMode': speechOutputMode.name,
    'highContrast': highContrast,
    'autoReconnect': autoReconnect,
    'demoMode': demoMode,
  };

  /// Builds settings from stored JSON, falling back to defaults per field.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      feedbackMode: FeedbackMode.fromName(json['feedbackMode'] as String?),
      speechEnabled: json['speechEnabled'] as bool? ?? true,
      speechOutputMode: SpeechOutputMode.fromName(
        json['speechOutputMode'] as String?,
      ),
      highContrast: json['highContrast'] as bool? ?? false,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      demoMode: json['demoMode'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.feedbackMode == feedbackMode &&
      other.speechEnabled == speechEnabled &&
      other.speechOutputMode == speechOutputMode &&
      other.highContrast == highContrast &&
      other.autoReconnect == autoReconnect &&
      other.demoMode == demoMode;

  @override
  int get hashCode => Object.hash(
    feedbackMode,
    speechEnabled,
    speechOutputMode,
    highContrast,
    autoReconnect,
    demoMode,
  );
}
