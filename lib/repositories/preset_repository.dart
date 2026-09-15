import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/preset.dart';

/// Persists the user's presets as a single JSON-encoded list in
/// [SharedPreferences].
///
/// Loading is tolerant: malformed entries are dropped rather than throwing, so
/// one bad record can never make the whole list unreadable.
class PresetRepository {
  PresetRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'presets_v1';

  List<Preset> loadPresets() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final presets = <Preset>[];
      for (final item in decoded) {
        if (item is Map) {
          final preset = Preset.fromJson(Map<String, dynamic>.from(item));
          if (preset != null) presets.add(preset);
        }
      }
      return presets;
    } catch (_) {
      return const [];
    }
  }

  Future<void> savePresets(List<Preset> presets) async {
    final encoded = jsonEncode(presets.map((p) => p.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }
}
