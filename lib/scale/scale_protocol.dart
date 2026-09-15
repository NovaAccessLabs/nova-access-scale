import 'package:flutter/foundation.dart';

/// Connection lifecycle of a scale, surfaced to the controller and UI.
enum ScaleConnectionStatus { disconnected, connecting, connected, error }

/// A scale the user can connect to — either a real BLE device discovered during
/// a scan or the simulated demo device. [id] is a stable identifier (the BLE
/// remote id for real devices) used to reconnect.
@immutable
class ScaleDevice {
  const ScaleDevice({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is ScaleDevice && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'ScaleDevice($id, $name)';
}

/// A scale communication protocol.
///
/// This is the single abstraction the rest of the app talks to — UI and the
/// controller never reference BLE or device-specific framing directly. Each
/// supported scale (and the demo) provides one implementation. New scales are
/// added by implementing this interface and registering it in
/// [ScaleProtocolRegistry], with no UI changes.
abstract interface class ScaleProtocol {
  /// Stable identifier for this protocol (e.g. `myscale`, `mock`).
  String get protocolId;

  /// Whether this protocol recognizes a device advertising [advertisedName].
  /// Used to filter scan results.
  bool isSupported(String? advertisedName);

  /// Current connection status.
  ScaleConnectionStatus get status;

  /// Stream of connection status changes.
  Stream<ScaleConnectionStatus> get statusStream;

  /// Live weight in grams (may be negative). Emits while connected.
  Stream<double> get weightStream;

  /// The most recent weight in grams.
  double get currentWeight;

  /// Connects to [device] and begins streaming weight.
  Future<void> connect(ScaleDevice device);

  /// Disconnects and stops streaming.
  Future<void> disconnect();

  /// Resets the scale reading to zero. The active target is unaffected.
  Future<void> tare();

  /// Releases all resources (streams, timers, BLE subscriptions).
  Future<void> dispose();
}
