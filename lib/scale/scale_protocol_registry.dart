import 'scale_protocol.dart';

typedef ProtocolMatcher = bool Function(String? advertisedName);
typedef ProtocolFactory = ScaleProtocol Function();

/// Describes a supported scale protocol: how to recognize its devices during a
/// scan, and how to create a fresh protocol instance to talk to one.
class ScaleProtocolDescriptor {
  const ScaleProtocolDescriptor({
    required this.protocolId,
    required this.displayName,
    required this.matches,
    required this.create,
  });

  final String protocolId;

  /// Human-readable model/brand name for this protocol, not localized.
  final String displayName;

  final ProtocolMatcher matches;
  final ProtocolFactory create;
}

/// The set of scale protocols the app knows how to talk to.
///
/// [ScaleBleService] consults this to filter scan results, and the controller
/// uses it to build the right protocol for a chosen device. Adding a new scale
/// is a one-line registration here — no UI or controller changes.
class ScaleProtocolRegistry {
  ScaleProtocolRegistry(this.descriptors);

  final List<ScaleProtocolDescriptor> descriptors;

  ScaleProtocolDescriptor? descriptorForName(String? advertisedName) {
    for (final descriptor in descriptors) {
      if (descriptor.matches(advertisedName)) return descriptor;
    }
    return null;
  }

  bool isSupported(String? advertisedName) =>
      descriptorForName(advertisedName) != null;

  ScaleProtocol? createForName(String? advertisedName) =>
      descriptorForName(advertisedName)?.create();
}
