import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/models/app_settings.dart';
import 'package:nova_access_scale/models/feedback_mode.dart';
import 'package:nova_access_scale/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsRepository> _repo([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsRepository(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns defaults when nothing is stored', () async {
    final repo = await _repo();
    expect(repo.load(), const AppSettings());
  });

  test('defaults to sound only — vibration is opt-in', () async {
    final repo = await _repo();

    expect(repo.load().feedbackMode, FeedbackMode.audio);
    expect(repo.load().feedbackMode.usesVibration, isFalse);
  });

  test('an unrecognised stored mode falls back to sound only', () async {
    // A corrupt or future value must not silently switch on a channel the user
    // never asked for.
    expect(FeedbackMode.fromName('bogus'), FeedbackMode.audio);
    expect(FeedbackMode.fromName(null), FeedbackMode.audio);
  });

  test('round-trips settings through save and load', () async {
    final repo = await _repo();
    const settings = AppSettings(
      feedbackMode: FeedbackMode.vibration,
      speechEnabled: false,
      highContrast: true,
      autoReconnect: false,
      demoMode: true,
    );

    await repo.save(settings);

    expect(repo.load(), settings);
  });

  test('falls back to defaults for corrupt data', () async {
    final repo = await _repo({'settings_v1': 'not json'});
    expect(repo.load(), const AppSettings());
  });

  test('persists last target and last device id', () async {
    final repo = await _repo();
    expect(repo.loadLastTarget(), isNull);
    expect(repo.loadLastDeviceId(), isNull);

    await repo.saveLastTarget(18);
    await repo.saveLastDevice('AA:BB:CC', 'MY_SCALE42');

    expect(repo.loadLastTarget(), 18);
    expect(repo.loadLastDeviceId(), 'AA:BB:CC');
    expect(repo.loadLastDeviceName(), 'MY_SCALE42');

    await repo.clearLastDevice();
    expect(repo.loadLastDeviceId(), isNull);
    expect(repo.loadLastDeviceName(), isNull);
  });

  test('rejects invalid last target values', () async {
    final repo = await _repo({'last_target_grams': 0});
    expect(repo.loadLastTarget(), isNull);
  });
}
