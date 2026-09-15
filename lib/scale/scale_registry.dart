import 'myscale_scale_protocol.dart';
import 'scale_protocol_registry.dart';

/// Builds the registry of supported scale protocols.
///
/// This is the single place new scales are added: register a descriptor and the
/// scanning + connection layers pick it up with no further changes. The demo
/// (mock) scale is handled separately by the controller and is not registered
/// here.
ScaleProtocolRegistry buildScaleRegistry() {
  return ScaleProtocolRegistry([
    ScaleProtocolDescriptor(
      protocolId: 'myscale',
      displayName: 'MyScale',
      matches: MyScaleScaleProtocol.matchesAdvertisedName,
      create: MyScaleScaleProtocol.new,
    ),
  ]);
}
