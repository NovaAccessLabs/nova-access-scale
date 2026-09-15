import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/scale/scale_registry.dart';

/// A representative advertised name for every registered protocol.
///
/// Matching is first-match-wins over the registration order, so a protocol
/// registered later can be shadowed by an earlier one with a looser matcher.
/// Pinning one name per protocol catches that.
const Map<String, String> _advertisedNames = {'myscale': 'MY_SCALE'};

void main() {
  final registry = buildScaleRegistry();

  test('every registered protocol has a sample name pinned here', () {
    expect(
      registry.descriptors.map((d) => d.protocolId).toSet(),
      _advertisedNames.keys.toSet(),
    );
  });

  test('protocol ids and display names are unique', () {
    expect(
      registry.descriptors.map((d) => d.protocolId).toSet(),
      hasLength(registry.descriptors.length),
    );
    expect(
      registry.descriptors.map((d) => d.displayName).toSet(),
      hasLength(registry.descriptors.length),
    );
  });

  group('descriptorForName', () {
    for (final entry in _advertisedNames.entries) {
      test('${entry.value} resolves to ${entry.key}', () {
        expect(registry.descriptorForName(entry.value)?.protocolId, entry.key);
      });
    }

    test('an unknown device matches nothing', () {
      expect(registry.descriptorForName('Some Other Device'), isNull);
      expect(registry.descriptorForName(null), isNull);
    });
  });

  test('createForName builds the matching protocol', () {
    for (final entry in _advertisedNames.entries) {
      final protocol = registry.createForName(entry.value);
      expect(protocol?.protocolId, entry.key);
    }
  });
}
