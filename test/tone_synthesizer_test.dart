import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/tone_synthesizer.dart';

String _ascii(Uint8List bytes, int start, int length) =>
    String.fromCharCodes(bytes.sublist(start, start + length));

int _u32(Uint8List bytes, int at) =>
    bytes.buffer.asByteData().getUint32(at, Endian.little);

void main() {
  const synth = ToneSynthesizer(sampleRate: 8000, fadeMs: 1);

  test('emits a valid WAV header', () {
    final wav = synth.synthesize(const [ToneSegment(440, 100)]);
    expect(_ascii(wav, 0, 4), 'RIFF');
    expect(_ascii(wav, 8, 4), 'WAVE');
    expect(_ascii(wav, 12, 4), 'fmt ');
    expect(_ascii(wav, 36, 4), 'data');
    // PCM, mono, 16-bit, 8 kHz.
    final header = wav.buffer.asByteData();
    expect(header.getUint16(20, Endian.little), 1); // PCM
    expect(header.getUint16(22, Endian.little), 1); // mono
    expect(header.getUint32(24, Endian.little), 8000); // sample rate
    expect(header.getUint16(34, Endian.little), 16); // bits
  });

  test('data length matches sample count', () {
    // 100 ms at 8 kHz = 800 samples * 2 bytes = 1600 bytes of PCM.
    final wav = synth.synthesize(const [ToneSegment(440, 100)]);
    expect(_u32(wav, 40), 1600); // data chunk size
    expect(_u32(wav, 4), 36 + 1600); // RIFF chunk size
    expect(wav.length, 44 + 1600);
  });

  test('concatenates multiple segments', () {
    final wav = synth.synthesize(const [
      ToneSegment(440, 50),
      ToneSegment(0, 50), // silence
      ToneSegment(880, 50),
    ]);
    // 3 * 50 ms at 8 kHz = 1200 samples * 2 = 2400 bytes.
    expect(_u32(wav, 40), 2400);
    expect(wav.length, 44 + 2400);
  });

  test('silence segment is all zero samples', () {
    final wav = synth.synthesize(const [ToneSegment(0, 10)]);
    final pcm = wav.sublist(44);
    expect(pcm.every((b) => b == 0), isTrue);
  });

  test('predefined earcons synthesize without error', () {
    expect(synth.synthesize(FeedbackTones.approach).length, greaterThan(44));
    expect(synth.synthesize(FeedbackTones.reached).length, greaterThan(44));
    expect(synth.synthesize(FeedbackTones.over).length, greaterThan(44));
  });
}
