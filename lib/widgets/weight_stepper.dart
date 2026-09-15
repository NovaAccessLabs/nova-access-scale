import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The accessible target-weight control: a large live value with four step
/// buttons (-10, -1, +1, +10). No slider (a deliberate accessibility decision —
/// sliders are imprecise for low-vision/motor users and have crashed TalkBack
/// on this Flutter version). Holding a button repeats the step.
///
/// Screen readers see four labeled buttons plus a live-region value, so the
/// current target is announced as it changes. Values are whole grams, clamped
/// to [min]..[max].
class WeightStepper extends StatelessWidget {
  const WeightStepper({
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 5000,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  void _step(int delta) {
    final next = (value + delta).clamp(min, max);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live value readout.
        Semantics(
          liveRegion: true,
          label: l10n.targetValue(value),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  textAlign: TextAlign.center,
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: AppTypography.weightReadout(colors),
                    children: [
                      TextSpan(text: '$value'),
                      TextSpan(
                        text: ' ${l10n.gramsUnit}',
                        style: TextStyle(
                          fontSize: 28,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StepButton(
              label: l10n.decreaseByGrams(10),
              display: '−10', // minus sign + 10
              onStep: () => _step(-10),
            ),
            const SizedBox(width: 12),
            _StepButton(
              label: l10n.decreaseByGrams(1),
              display: '−1',
              onStep: () => _step(-1),
            ),
            const SizedBox(width: 12),
            _StepButton(
              label: l10n.increaseByGrams(1),
              display: '+1',
              onStep: () => _step(1),
              emphasized: true,
            ),
            const SizedBox(width: 12),
            _StepButton(
              label: l10n.increaseByGrams(10),
              display: '+10',
              onStep: () => _step(10),
              emphasized: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// A single step button: tap for one step, hold to repeat. Exposes a button
/// semantics node with [label] and a tap action (one step) for screen readers,
/// hiding the inner visual gesture from the semantics tree.
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.label,
    required this.display,
    required this.onStep,
    this.emphasized = false,
  });

  final String label;
  final String display;
  final VoidCallback onStep;
  final bool emphasized;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    widget.onStep();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => widget.onStep(),
    );
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = widget.emphasized ? colors.accentFill : colors.surface;
    final foreground = widget.emphasized
        ? colors.onAccentFill
        : colors.textPrimary;

    return Expanded(
      child: Semantics(
        button: true,
        label: widget.label,
        onTap: widget.onStep,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: widget.onStep,
            onLongPressStart: (_) => _startRepeat(),
            onLongPressEnd: (_) => _stopRepeat(),
            onLongPressCancel: _stopRepeat,
            child: Container(
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border, width: 1.5),
              ),
              child: Text(
                widget.display,
                style: TextStyle(
                  fontFamily: AppTypography.uiFontFamily,
                  fontWeight: AppTypography.semiBold,
                  fontSize: 24,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
