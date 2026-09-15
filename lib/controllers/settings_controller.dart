import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/feedback_mode.dart';
import '../models/speech_output_mode.dart';
import '../repositories/settings_repository.dart';

/// Holds [AppSettings] and persists every change.
///
/// The feedback configuration and high-contrast toggle are derived from this
/// controller; widgets listen to it and rebuild on change. Light/dark theme
/// and locale are not settings-driven — they follow the OS automatically.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository) : _settings = _repository.load();

  final SettingsRepository _repository;
  AppSettings _settings;

  AppSettings get settings => _settings;

  Future<void> _apply(AppSettings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }

  Future<void> setFeedbackMode(FeedbackMode mode) =>
      _apply(_settings.copyWith(feedbackMode: mode));

  Future<void> setSpeechEnabled(bool enabled) =>
      _apply(_settings.copyWith(speechEnabled: enabled));

  Future<void> setSpeechOutputMode(SpeechOutputMode mode) =>
      _apply(_settings.copyWith(speechOutputMode: mode));

  Future<void> setHighContrast(bool enabled) =>
      _apply(_settings.copyWith(highContrast: enabled));

  Future<void> setAutoReconnect(bool enabled) =>
      _apply(_settings.copyWith(autoReconnect: enabled));

  Future<void> setDemoMode(bool enabled) =>
      _apply(_settings.copyWith(demoMode: enabled));
}
