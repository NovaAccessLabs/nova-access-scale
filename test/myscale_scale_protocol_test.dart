import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/scale/myscale_scale_protocol.dart';

/// Builds a 15-byte MyScale weight frame for [weight1000] (= grams * 1000). The
/// 28-bit magnitude spans the low nibble of byte 3 and bytes 4-6. [signNibble]
/// is the high nibble of byte 2 (0x8 or 0xC means negative).
List<int> _frame(int weight1000, {int signNibble = 0x0}) {
  final d = List<int>.filled(15, 0);
  d[2] = signNibble << 4;
  d[3] = (weight1000 >> 24) & 0x0F;
  d[4] = (weight1000 >> 16) & 0xFF;
  d[5] = (weight1000 >> 8) & 0xFF;
  d[6] = weight1000 & 0xFF;
  return d;
}

void main() {
  group('parseWeight', () {
    test('decodes a whole-gram weight', () {
      expect(MyScaleScaleProtocol.parseWeight(_frame(18000)), 18.0);
    });

    test('decodes a fractional weight', () {
      expect(MyScaleScaleProtocol.parseWeight(_frame(18345)), 18.345);
    });

    test('applies the negative sign (high nibble 0x8)', () {
      expect(
        MyScaleScaleProtocol.parseWeight(_frame(5250, signNibble: 0x8)),
        -5.25,
      );
    });

    test('applies the negative sign (high nibble 0xC)', () {
      expect(
        MyScaleScaleProtocol.parseWeight(_frame(5250, signNibble: 0xC)),
        -5.25,
      );
    });

    test('rejects a short frame', () {
      expect(
        MyScaleScaleProtocol.parseWeight(_frame(18000).sublist(0, 14)),
        isNull,
      );
    });
  });

  group('matchesAdvertisedName', () {
    test('matches each known prefix', () {
      expect(
        MyScaleScaleProtocol.matchesAdvertisedName('blackcoffee-01'),
        isTrue,
      );
      expect(MyScaleScaleProtocol.matchesAdvertisedName('my_scale'), isTrue);
      expect(MyScaleScaleProtocol.matchesAdvertisedName('MY_SCALE_2'), isTrue);
    });

    test('does not match other names or null', () {
      expect(MyScaleScaleProtocol.matchesAdvertisedName('scale'), isFalse);
      expect(MyScaleScaleProtocol.matchesAdvertisedName(null), isFalse);
    });
  });

  test('tare command is the 20-byte AC 40 ... D2 D2 sequence', () {
    final cmd = MyScaleScaleProtocol.tareCommand;
    expect(cmd.length, 20);
    expect(cmd.first, 0xAC);
    expect(cmd[1], 0x40);
    expect(cmd[18], 0xD2);
    expect(cmd[19], 0xD2);
  });
}
