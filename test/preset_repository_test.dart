import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/models/preset.dart';
import 'package:nova_access_scale/repositories/preset_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PresetRepository> _repo([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return PresetRepository(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns empty list when nothing is stored', () async {
    final repo = await _repo();
    expect(repo.loadPresets(), isEmpty);
  });

  test('round-trips presets through save and load', () async {
    final repo = await _repo();
    final presets = [
      const Preset(name: 'Espresso', targetWeightGrams: 18),
      const Preset(name: 'Pour over', targetWeightGrams: 30),
    ];

    await repo.savePresets(presets);

    expect(repo.loadPresets(), presets);
  });

  test('drops malformed entries but keeps valid ones', () async {
    final raw = jsonEncode([
      {'name': 'Espresso', 'targetWeightGrams': 18},
      {'name': '', 'targetWeightGrams': 20}, // empty name -> invalid
      {'name': 'Bad', 'targetWeightGrams': 0}, // below 1g -> invalid
      {'name': 'NoWeight'}, // missing weight -> invalid
      'not-an-object', // wrong type -> ignored
      {'name': 'Latte', 'targetWeightGrams': 200},
    ]);
    final repo = await _repo({'presets_v1': raw});

    expect(repo.loadPresets(), const [
      Preset(name: 'Espresso', targetWeightGrams: 18),
      Preset(name: 'Latte', targetWeightGrams: 200),
    ]);
  });

  test('returns empty list for corrupt (non-JSON) data', () async {
    final repo = await _repo({'presets_v1': 'definitely not json'});
    expect(repo.loadPresets(), isEmpty);
  });

  test('returns empty list when stored value is not a list', () async {
    final repo = await _repo({
      'presets_v1': jsonEncode({'oops': true}),
    });
    expect(repo.loadPresets(), isEmpty);
  });
}
