import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Persists [AppSettings] plus two small pieces of session state that support
/// the main flow but are not user-facing settings: the last target weight
/// ("Start last target") and the last connected device id (auto-reconnect).
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _settingsKey = 'settings_v1';
  static const String _lastTargetKey = 'last_target_grams';
  static const String _lastDeviceKey = 'last_device_id';
  static const String _lastDeviceNameKey = 'last_device_name';

  AppSettings load() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
      return const AppSettings();
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// The last target weight in grams, or null if none has been set.
  int? loadLastTarget() {
    final value = _prefs.getInt(_lastTargetKey);
    if (value == null || value < 1) return null;
    return value;
  }

  Future<void> saveLastTarget(int grams) async {
    await _prefs.setInt(_lastTargetKey, grams);
  }

  /// The BLE id of the last connected scale, for auto-reconnect.
  String? loadLastDeviceId() => _prefs.getString(_lastDeviceKey);

  /// The display name of the last connected scale (for the reconnect UI).
  String? loadLastDeviceName() => _prefs.getString(_lastDeviceNameKey);

  Future<void> saveLastDevice(String deviceId, String name) async {
    await _prefs.setString(_lastDeviceKey, deviceId);
    await _prefs.setString(_lastDeviceNameKey, name);
  }

  Future<void> clearLastDevice() async {
    await _prefs.remove(_lastDeviceKey);
    await _prefs.remove(_lastDeviceNameKey);
  }
}
