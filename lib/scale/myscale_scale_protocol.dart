import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import 'scale_protocol.dart';

/// BLE protocol for MyScale scales (advertised as `blackcoffee` / `my_scale` /
/// `MY_SCALE`).
///
/// Ported from the ESP32/NimBLE reference at
/// github.com/Zer0-bit/esp-arduino-ble-scales (src/scales/myscale.*).
/// The pure helpers ([parseWeight], [matchesAdvertisedName]) are unit-tested;
/// the BLE path cannot be unit-tested.
///
/// HARDWARE-VERIFIED on a physical device advertising as `MY_SCALE`
/// (2026-08-11, Android; the BLE transport at the time was flutter_blue_plus,
/// since replaced by universal_ble and re-verified 2026-09-05):
///  * discovery — the device appears in the scan list under its advertised name,
///  * live weight stream — values track continuously while weight changes,
///  * sign handling — negative readings (e.g. -37.0 g after removing a tared
///    load) parse and display correctly,
///  * tare (20-byte command on the write characteristic) — returns to 0.0 g.
///
/// RE-VERIFIED on `universal_ble` (2026-09-05, Android): discovery, connect,
/// live weight, and tare all confirmed again on the same physical device.
///

/// Not yet exercised on this hardware: sustained multi-minute streaming, and
/// whether the scale keeps streaming or goes quiet once the weight settles
/// (the case FeedbackCoordinator's confirm-timer backstop exists for).
class MyScaleScaleProtocol implements ScaleProtocol {
  // 16-bit ids expanded against the standard Bluetooth base UUID.
  static const String _serviceUuid = '0000ffb0-0000-1000-8000-00805f9b34fb';
  static const String _weightCharUuid = '0000ffb2-0000-1000-8000-00805f9b34fb';
  static const String _commandCharUuid = '0000ffb1-0000-1000-8000-00805f9b34fb';

  static const List<String> _namePrefixes = [
    'blackcoffee',
    'my_scale',
    'MY_SCALE',
  ];

  /// Tare command written to the command characteristic (`0xFFB1`).
  static const List<int> tareCommand = [
    0xAC, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
    0x00, 0x00, 0xD2, 0xD2,
  ];

  final StreamController<double> _weightController =
      StreamController<double>.broadcast();
  final StreamController<ScaleConnectionStatus> _statusController =
      StreamController<ScaleConnectionStatus>.broadcast();

  String? _deviceId;
  StreamSubscription<Uint8List>? _valueSub;
  StreamSubscription<bool>? _connSub;

  double _currentWeight = 0;
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;

  @override
  String get protocolId => 'myscale';

  @override
  bool isSupported(String? advertisedName) =>
      matchesAdvertisedName(advertisedName);

  static bool matchesAdvertisedName(String? advertisedName) =>
      advertisedName != null &&
      _namePrefixes.any((p) => advertisedName.startsWith(p));

  @override
  ScaleConnectionStatus get status => _status;

  @override
  Stream<ScaleConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<double> get weightStream => _weightController.stream;

  @override
  double get currentWeight => _currentWeight;

  /// Decodes a MyScale weight frame to grams, or null if the frame is too short.
  ///
  /// Frame is at least 15 bytes. The high nibble of byte 2 carries the sign
  /// (`0x8` or `0xC` = negative). The magnitude is a 28-bit big-endian value:
  /// the low nibble of byte 3 plus bytes 4-6, in thousandths of a gram.
  static double? parseWeight(List<int> d) {
    if (d.length < 15) return null;

    final highNibble = d[2] >> 4;
    final negative = highNibble == 0x8 || highNibble == 0xC;

    final raw = ((d[3] & 0x0F) << 24) | (d[4] << 16) | (d[5] << 8) | d[6];
    final grams = raw / 1000.0;
    return negative ? -grams : grams;
  }

  @override
  Future<void> connect(ScaleDevice device) async {
    _setStatus(ScaleConnectionStatus.connecting);
    _deviceId = device.id;

    _connSub = UniversalBle.connectionStream(device.id).listen((connected) {
      if (!connected) _setStatus(ScaleConnectionStatus.disconnected);
    });

    await UniversalBle.connect(device.id, timeout: const Duration(seconds: 15));
    final services = await UniversalBle.discoverServices(device.id);
    final service = services.firstWhere((s) => s.uuid == _serviceUuid);

    service.characteristics.firstWhere((c) => c.uuid == _weightCharUuid);
    service.characteristics.firstWhere((c) => c.uuid == _commandCharUuid);

    // Subscribe before enabling notifications so no frame is missed.
    _valueSub = UniversalBle.characteristicValueStream(
      device.id,
      _weightCharUuid,
    ).listen(_onData);
    await UniversalBle.subscribeNotifications(
      device.id,
      _serviceUuid,
      _weightCharUuid,
    );

    _setStatus(ScaleConnectionStatus.connected);
  }

  void _onData(List<int> data) {
    final grams = parseWeight(data);
    if (grams == null) return; // discard invalid frame
    _currentWeight = grams;
    if (!_weightController.isClosed) _weightController.add(grams);
  }

  @override
  Future<void> tare() async {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    final command = Uint8List.fromList(tareCommand);
    try {
      // Lower latency; matters for real-time feedback.
      await UniversalBle.write(
        deviceId,
        _serviceUuid,
        _commandCharUuid,
        command,
        withoutResponse: true,
      );
    } catch (_) {
      try {
        await UniversalBle.write(
          deviceId,
          _serviceUuid,
          _commandCharUuid,
          command,
          withoutResponse: false,
        );
      } catch (_) {
        // Tare failed; the next weight frame will still reflect reality.
      }
    }
  }

  @override
  Future<void> disconnect() async {
    await _valueSub?.cancel();
    _valueSub = null;
    final deviceId = _deviceId;
    if (deviceId != null) {
      try {
        await UniversalBle.disconnect(deviceId);
      } catch (_) {}
    }
    _setStatus(ScaleConnectionStatus.disconnected);
  }

  void _setStatus(ScaleConnectionStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  @override
  Future<void> dispose() async {
    await _connSub?.cancel();
    await _valueSub?.cancel();
    _connSub = null;
    _valueSub = null;
    final deviceId = _deviceId;
    if (deviceId != null) {
      try {
        await UniversalBle.disconnect(deviceId);
      } catch (_) {}
    }
    await _weightController.close();
    await _statusController.close();
  }
}
