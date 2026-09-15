import 'dart:async';
import 'dart:math';

import 'scale_protocol.dart';

/// A simulated scale for development, accessibility testing, and demos.
///
/// Two ways to drive the weight:
///  * Manually via [setWeight] / [addWeight] — used by tests for deterministic
///    behavior.
///  * Automatically via [autoRamp] — used by demo mode. While connected, the
///    weight ramps gradually from 0 toward [rampCeiling] with occasional
///    pauses (so the percentage-based cadence speeds up and the pause-triggered
///    speech announcements fire), then holds. [tare] resets it to 0, which
///    restarts the ramp — giving a hands-free, eyes-free demonstration of the
///    full approach → reached → over-target experience.
class MockScaleProtocol implements ScaleProtocol {
  MockScaleProtocol({
    this.autoRamp = false,
    this.tickInterval = const Duration(milliseconds: 350),
    this.rampCeiling = 100.0,
    Random? random,
  }) : _random = random ?? Random();

  /// Stable id of the simulated device. The UI pairs this with a localized
  /// display name.
  static const String deviceId = 'mock-demo-scale';

  final bool autoRamp;
  final Duration tickInterval;
  final double rampCeiling;
  final Random _random;

  final _weightController = StreamController<double>.broadcast();
  final _statusController = StreamController<ScaleConnectionStatus>.broadcast();

  Timer? _rampTimer;
  double _currentWeight = 0;
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;

  @override
  String get protocolId => 'mock';

  @override
  bool isSupported(String? advertisedName) => advertisedName == deviceId;

  @override
  ScaleConnectionStatus get status => _status;

  @override
  Stream<ScaleConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<double> get weightStream => _weightController.stream;

  @override
  double get currentWeight => _currentWeight;

  @override
  Future<void> connect(ScaleDevice device) async {
    _setStatus(ScaleConnectionStatus.connecting);
    // Simulate the brief BLE connection handshake.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _setStatus(ScaleConnectionStatus.connected);
    _emitWeight(0);
    if (autoRamp) {
      _rampTimer = Timer.periodic(tickInterval, (_) => _tick());
    }
  }

  @override
  Future<void> disconnect() async {
    _rampTimer?.cancel();
    _rampTimer = null;
    _setStatus(ScaleConnectionStatus.disconnected);
  }

  @override
  Future<void> tare() async {
    _emitWeight(0);
  }

  /// Sets the simulated weight directly (test/manual control).
  void setWeight(double grams) => _emitWeight(grams);

  /// Adds [grams] to the simulated weight (test/manual control).
  void addWeight(double grams) => _emitWeight(_currentWeight + grams);

  void _tick() {
    if (_status != ScaleConnectionStatus.connected) return;
    if (_currentWeight >= rampCeiling) return; // hold at the ceiling
    // Occasionally pause to exercise the stability/announcement logic.
    if (_random.nextDouble() < 0.15) return;
    final increment = 0.8 + _random.nextDouble(); // 0.8–1.8 g
    _emitWeight(_currentWeight + increment);
  }

  void _emitWeight(double grams) {
    _currentWeight = grams;
    if (!_weightController.isClosed) _weightController.add(grams);
  }

  void _setStatus(ScaleConnectionStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  @override
  Future<void> dispose() async {
    _rampTimer?.cancel();
    _rampTimer = null;
    await _weightController.close();
    await _statusController.close();
  }
}
