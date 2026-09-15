import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/controllers/scale_controller.dart';
import 'package:nova_access_scale/controllers/settings_controller.dart';
import 'package:nova_access_scale/feedback/feedback_coordinator.dart';
import 'package:nova_access_scale/feedback/feedback_outputs.dart';
import 'package:nova_access_scale/repositories/settings_repository.dart';
import 'package:nova_access_scale/scale/scale_ble_service.dart';
import 'package:nova_access_scale/scale/scale_protocol.dart';
import 'package:nova_access_scale/scale/scale_protocol_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// A protocol that records tare calls and reports connected immediately.
class _FakeProtocol implements ScaleProtocol {
  int tareCount = 0;
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;
  final _statusController = StreamController<ScaleConnectionStatus>.broadcast();
  final _weightController = StreamController<double>.broadcast();

  @override
  String get protocolId => 'fake';
  @override
  bool isSupported(String? advertisedName) => true;
  @override
  ScaleConnectionStatus get status => _status;
  @override
  Stream<ScaleConnectionStatus> get statusStream => _statusController.stream;
  @override
  Stream<double> get weightStream => _weightController.stream;
  @override
  double get currentWeight => 0;
  @override
  Future<void> connect(ScaleDevice device) async {
    _status = ScaleConnectionStatus.connected;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    _status = ScaleConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  @override
  Future<void> tare() async => tareCount++;

  @override
  Future<void> dispose() async {
    if (!_statusController.isClosed) await _statusController.close();
    if (!_weightController.isClosed) await _weightController.close();
  }
}

ScaleController _controllerWith(
  SettingsRepository settingsRepo,
  SettingsController settings,
  _FakeProtocol fake,
) {
  final registry = ScaleProtocolRegistry([
    ScaleProtocolDescriptor(
      protocolId: 'fake',
      displayName: 'Fake scale',
      matches: (name) => name == 'FakeScale',
      create: () => fake,
    ),
  ]);
  return ScaleController(
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auto-reconnect on launch tares the scale', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsRepo = SettingsRepository(prefs);
    // A previous device exists; autoReconnect defaults true and demoMode false.
    await settingsRepo.saveLastDevice('dev-1', 'FakeScale');
    final settings = SettingsController(settingsRepo);

    final fake = _FakeProtocol();
    final scale = _controllerWith(settingsRepo, settings, fake);
    addTearDown(scale.dispose);

    scale.init(); // kicks off an unawaited auto-reconnect
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(scale.isConnected, isTrue);
    expect(fake.tareCount, 1);
  });

  test('manual connect does not auto-tare', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsRepo = SettingsRepository(prefs);
    final settings = SettingsController(settingsRepo);

    final fake = _FakeProtocol();
    final scale = _controllerWith(settingsRepo, settings, fake);
    addTearDown(scale.dispose);

    await scale.connect(const ScaleDevice(id: 'dev-1', name: 'FakeScale'));

    expect(scale.isConnected, isTrue);
    expect(fake.tareCount, 0);
  });

  // Regression: a scale found by one scan stayed in the list forever, even
  // after it was switched off and the user pressed "Scan for scales" again.
  // `discoveredScales` only emits when it *finds* something, so the fresh
  // subscription never fired and the controller kept the previous list.
  test('a new scan clears devices found by the previous one', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsRepo = SettingsRepository(prefs);
    final settings = SettingsController(settingsRepo);

    final registry = ScaleProtocolRegistry([]);
    final ble = _FakeBleService(registry);
    final scale = ScaleController(
      settingsController: settings,
      settingsRepository: settingsRepo,
      bleService: ble,
      registry: registry,
      coordinator: FeedbackCoordinator(
        audio: _NoopPulse(),
        haptic: _NoopPulse(),
        speech: _NoopSpeech(),
      ),
    );
    addTearDown(scale.dispose);

    // First scan finds the scale.
    await scale.startScan();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(scale.discoveredDevices, hasLength(1));

    // The scale is switched off, so the second scan finds nothing at all.
    ble.findsNothing = true;
    await scale.startScan();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      scale.discoveredDevices,
      isEmpty,
      reason: 'a powered-off scale must not linger from the previous scan',
    );
  });
}

/// A [ScaleBleService] that never touches the BLE plugin. Emits one device
/// until [findsNothing] is set, then emits nothing — the "scale switched off"
/// case, where the stream stays silent for the whole scan.
class _FakeBleService extends ScaleBleService {
  _FakeBleService(super.registry);

  bool findsNothing = false;

  @override
  Stream<List<ScaleDevice>> get discoveredScales async* {
    if (findsNothing) return;
    yield const [ScaleDevice(id: 'dev-1', name: 'MY_SCALE')];
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {}

  @override
  Future<void> stopScan() async {}
}
