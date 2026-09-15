import 'package:flutter_test/flutter_test.dart';
import 'package:nova_access_scale/feedback/stability_detector.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  test('fires once after the weight is held for the hold duration', () {
    final d = StabilityDetector();
    expect(d.addSample(0, ms(0)), isFalse); // anchor
    expect(d.addSample(0.1, ms(200)), isFalse); // within tolerance, too soon
    expect(d.addSample(0.2, ms(900)), isFalse);
    expect(d.addSample(0.1, ms(1000)), isTrue); // held 1000 ms -> pause
  });

  test('does not fire again while the weight stays still', () {
    final d = StabilityDetector();
    d.addSample(0, ms(0));
    expect(d.addSample(0, ms(1000)), isTrue);
    expect(d.addSample(0, ms(1500)), isFalse);
    expect(d.addSample(0.3, ms(3000)), isFalse);
  });

  test('re-arms after movement beyond tolerance, then fires again', () {
    final d = StabilityDetector();
    d.addSample(0, ms(0));
    expect(d.addSample(0, ms(1000)), isTrue); // first pause

    // Add weight: movement beyond tolerance re-anchors.
    expect(d.addSample(5, ms(1300)), isFalse);
    // Hold at the new level for >= 1000 ms.
    expect(d.addSample(5.1, ms(2400)), isTrue); // second pause
  });

  test('never fires during a continuous pour', () {
    final d = StabilityDetector();
    var fired = false;
    // +1 g every 100 ms: each sample exceeds tolerance from the anchor.
    for (var t = 0; t <= 3000; t += 100) {
      if (d.addSample(t / 100.0, ms(t))) fired = true;
    }
    expect(fired, isFalse);
  });

  test('reset clears state so the next hold fires fresh', () {
    final d = StabilityDetector();
    d.addSample(10, ms(0));
    expect(d.addSample(10, ms(1000)), isTrue);
    d.reset();
    expect(d.addSample(10, ms(1100)), isFalse); // new anchor after reset
    expect(d.addSample(10, ms(2200)), isTrue);
  });
}
