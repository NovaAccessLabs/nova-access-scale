import 'package:flutter/foundation.dart';

import '../models/preset.dart';
import '../repositories/preset_repository.dart';

/// Holds the user's presets and persists every mutation.
///
/// Supports create, rename, delete, select. (Selecting
/// a preset applies its target — that lives in ScaleController; this controller
/// just owns the list.)
class PresetController extends ChangeNotifier {
  PresetController(this._repository)
    : _presets = List<Preset>.of(_repository.loadPresets());

  final PresetRepository _repository;
  List<Preset> _presets;

  List<Preset> get presets => List.unmodifiable(_presets);

  Future<void> add(Preset preset) async {
    _presets = [..._presets, preset];
    notifyListeners();
    await _persist();
  }

  /// Replaces the preset at [index] (used for rename / edit).
  Future<void> replaceAt(int index, Preset preset) async {
    if (index < 0 || index >= _presets.length) return;
    final next = List<Preset>.of(_presets);
    next[index] = preset;
    _presets = next;
    notifyListeners();
    await _persist();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _presets.length) return;
    final next = List<Preset>.of(_presets)..removeAt(index);
    _presets = next;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => _repository.savePresets(_presets);
}
