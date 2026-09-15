import 'dart:math';
import 'dart:typed_data';

/// The amplitude envelope applied to a [ToneSegment].
enum ToneShape {
  /// Flat sustain with short linear fades at the edges — a steady beep.
  flat,

  /// Quick attack then a smooth decay to silence — a soft "ding". Gentler and
  /// less fatiguing than a flat beep for a cue that repeats often (the approach
  /// pulse).
  pluck,
}

/// One segment of a synthesized earcon: a tone of [frequencyHz] for
/// [durationMs], shaped by [shape]. A frequency of 0 produces silence (a gap
/// between tones).
class ToneSegment {
  const ToneSegment(
    this.frequencyHz,
    this.durationMs, {
    this.shape = ToneShape.flat,
    this.gain = 1.0,
  });

  final double frequencyHz;
  final int durationMs;
  final ToneShape shape;

  /// Relative loudness (0..1) multiplied into the synthesizer's peak amplitude,
  /// so one segment can be quieter than the others (e.g. a soft approach ding).
  final double gain;
}

/// Generates 16-bit PCM mono WAV audio in memory from [ToneSegment]s.
///
/// This is how the app produces its feedback tones: synthesized at runtime
/// rather than shipped as audio assets, which keeps latency low and the
/// bundle small. It is pure Dart with no plugin dependency, so it
/// is fully unit-testable; [AudioFeedbackService] handles the (untestable)
/// playback.
class ToneSynthesizer {
  const ToneSynthesizer({
    this.sampleRate = 44100,
    this.amplitude = 0.4,
    this.fadeMs = 12,
  });

  final int sampleRate;

  /// Peak amplitude as a fraction of full scale (kept below 1.0 to avoid
  /// clipping).
  final double amplitude;

  /// Linear fade-in/out at each tone's edges, in milliseconds, to avoid the
  /// audible click of a discontinuity.
  final int fadeMs;

  Uint8List synthesize(List<ToneSegment> segments) {
    var totalSamples = 0;
    for (final segment in segments) {
      totalSamples += _samplesFor(segment.durationMs);
    }
    final dataLength = totalSamples * 2; // 16-bit mono

    final pcm = ByteData(dataLength);
    var offset = 0;
    for (final segment in segments) {
      final n = _samplesFor(segment.durationMs);
      final fadeSamples = min(_samplesFor(fadeMs), n ~/ 2);
      for (var i = 0; i < n; i++) {
        double value;
        if (segment.frequencyHz <= 0) {
          value = 0;
        } else {
          final t = i / sampleRate;
          final envelope = _envelopeAt(i, n, fadeSamples, segment.shape);
          value =
              sin(2 * pi * segment.frequencyHz * t) *
              amplitude *
              segment.gain *
              envelope;
        }
        final sample = (value * 32767).round().clamp(-32768, 32767);
        pcm.setInt16(offset, sample, Endian.little);
        offset += 2;
      }
    }

    final builder = BytesBuilder()
      ..add(_wavHeader(dataLength))
      ..add(pcm.buffer.asUint8List());
    return builder.toBytes();
  }

  int _samplesFor(int milliseconds) =>
      (sampleRate * milliseconds / 1000).round();

  /// Amplitude envelope (0..1) for sample [i] of [n] total, with [fadeSamples]
  /// edge samples, per the segment's [shape].
  double _envelopeAt(int i, int n, int fadeSamples, ToneShape shape) {
    switch (shape) {
      case ToneShape.flat:
        if (fadeSamples <= 0) return 1;
        if (i < fadeSamples) return i / fadeSamples;
        if (i >= n - fadeSamples) return (n - i) / fadeSamples;
        return 1;
      case ToneShape.pluck:
        final attack = fadeSamples > 0 ? fadeSamples : 1;
        double env;
        if (i < attack) {
          env = 0.5 * (1 - cos(pi * i / attack)); // smooth raised-cosine attack
        } else {
          final progress = (i - attack) / (n - attack); // 0..1
          env = exp(-4.0 * progress); // exponential decay toward silence
        }
        // Guarantee true silence at the very end so there is no click.
        final tail = n - i;
        if (fadeSamples > 0 && tail < fadeSamples) {
          env *= tail / fadeSamples;
        }
        return env;
    }
  }

  Uint8List _wavHeader(int dataLength) {
    final header = ByteData(44);
    void writeAscii(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    const channels = 1;
    const bitsPerSample = 16;
    const bytesPerSample = bitsPerSample ~/ 8;

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // PCM fmt chunk size
    header.setUint16(20, 1, Endian.little); // audio format: PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
    header.setUint16(
      32,
      channels * bytesPerSample,
      Endian.little,
    ); // block align
    header.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataLength, Endian.little);
    return header.buffer.asUint8List();
  }
}

/// The three feedback earcons, shared by playback and tests.
abstract final class FeedbackTones {
  /// Soft "ding" repeated on the cadence while approaching: a warm mid pitch
  /// with a quick attack and a smooth decay, so a frequently-repeated cue
  /// sounds gentle rather than like a flat electronic beep.
  static const List<ToneSegment> approach = [
    ToneSegment(587, 160, shape: ToneShape.pluck, gain: 0.55),
  ];

  /// Rising two-note success cue.
  static const List<ToneSegment> reached = [
    ToneSegment(784, 120),
    ToneSegment(988, 220),
  ];

  /// Low double-buzz warning cue.
  static const List<ToneSegment> over = [
    ToneSegment(196, 160),
    ToneSegment(0, 70),
    ToneSegment(196, 160),
  ];
}
