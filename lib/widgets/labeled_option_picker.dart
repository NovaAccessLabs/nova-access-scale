import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A single option for [LabeledOptionPicker].
class PickerOption<T> {
  const PickerOption(this.value, this.label);
  final T value;
  final String label;
}

/// An accessible, slider-free chooser: a heading plus a wrap of large toggle
/// buttons. Exactly one is selected; the selection is conveyed by fill, a
/// check icon, **and** the `selected` semantic flag (never colour alone). Used
/// in Settings in place of radio lists, matching the NovaAccessBraille look.
class LabeledOptionPicker<T> extends StatelessWidget {
  const LabeledOptionPicker({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String label;
  final List<PickerOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: context.colors.accentText,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in options)
              _OptionChip<T>(
                option: option,
                isSelected: option.value == selected,
                onTap: () => onChanged(option.value),
                colors: context.colors,
              ),
          ],
        ),
      ],
    );
  }
}

class _OptionChip<T> extends StatelessWidget {
  const _OptionChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final PickerOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;
  final BrandColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final fg = isSelected ? c.onAccentFill : c.textPrimary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      // The tap handler must live on the semantics node, not only on the InkWell
      // below it: TalkBack's double-tap synthesizes a touch and would work
      // either way, but switch access and braille displays activate via
      // ACTION_CLICK, which an action-less node does not expose.
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: isSelected ? c.accentFill : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? c.accentFill : c.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: fg,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    option.label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
