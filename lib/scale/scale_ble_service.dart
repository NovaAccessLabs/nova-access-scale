import 'dart:async';

import 'package:universal_ble/universal_ble.dart';

import 'scale_protocol.dart';
import 'scale_protocol_registry.dart';

/// Thin wrapper over `universal_ble` for the parts of BLE that are *not*
/// device-specific: adapter state and scanning. Per-device connection and
/// framing live in each [ScaleProtocol] implementation.
///
/// MANUAL TEST REQUIRED: BLE scanning cannot be exercised in unit tests
/// (no host BLE adapter). Verify discovery, adapter-off handling, and
/// permission prompts on a physical Android device.
class ScaleBleService {
  ScaleBleService(this._registry);

  final ScaleProtocolRegistry _registry;

  bool _isScanningNow = false;
  final StreamController<bool> _isScanningController =
      StreamController<bool>.broadcast();
  Timer? _autoStopTimer;

  Stream<bool> get isScanning => _isScanningController.stream;

  bool get isScanningNow => _isScanningNow;

  /// Whether Bluetooth is switched off (as opposed to unauthorized), so the UI
  /// can show the right message. Only known after a [startScan] failure —
  /// universal_ble has no synchronous "current state" accessor.
  bool _isAdapterOff = false;

  bool get isAdapterOff => _isAdapterOff;

  /// Supported scales discovered so far, updated as the scan progresses.
  /// Results are de-duplicated by device id and filtered through the registry
  /// so only recognized devices (by advertised name) are surfaced.
  Stream<List<ScaleDevice>> get discoveredScales async* {
    final seen = <String>{};
    final devices = <ScaleDevice>[];
    await for (final result in UniversalBle.scanStream) {
      final name = result.name;
      if (name == null || name.isEmpty) continue;
      if (!_registry.isSupported(name)) continue;
      if (!seen.add(result.deviceId)) continue;
      devices.add(ScaleDevice(id: result.deviceId, name: name));
      yield List<ScaleDevice>.unmodifiable(devices);
    }
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_isScanningNow) return;
    _autoStopTimer?.cancel();
    _isAdapterOff = false;

    // The adapter can report `unknown` for a moment at cold launch (and while
    // the user answers the permission prompt); wait for it to resolve so we
    // don't surface a spurious error before the user has acted.
    var state = await UniversalBle.getBluetoothAvailabilityState();
    if (state == AvailabilityState.unknown) {
      state = await UniversalBle.availabilityStream
          .firstWhere((s) => s != AvailabilityState.unknown)
          .timeout(const Duration(seconds: 20), onTimeout: () => state);
    }
    if (state != AvailabilityState.poweredOn) {
      _isAdapterOff = state == AvailabilityState.poweredOff;
      throw StateError('Bluetooth adapter not ready: $state');
    }

    await UniversalBle.startScan();
    _isScanningNow = true;
    _isScanningController.add(true);
    _autoStopTimer = Timer(timeout, () => unawaited(stopScan()));
  }

  Future<void> stopScan() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    if (!_isScanningNow) return;
    _isScanningNow = false;
    _isScanningController.add(false);
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
  }
}
