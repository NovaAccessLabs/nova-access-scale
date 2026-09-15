import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/preset.dart';
import '../util/grams.dart';
import '../widgets/weight_stepper.dart';
import 'preset_editor_screen.dart';

/// Sets the target weight with the accessible stepper (no slider, integer grams
/// only). Confirm applies it to the scale; "save as preset" stores it for reuse.
class TargetSelectorScreen extends StatefulWidget {
  const TargetSelectorScreen({super.key});

  @override
  State<TargetSelectorScreen> createState() => _TargetSelectorScreenState();
}

class _TargetSelectorScreenState extends State<TargetSelectorScreen> {
  late int _value;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed from the current target once. didChangeDependencies can fire again
    // (e.g. on a locale change) — re-seeding would discard the user's edits.
    if (!_initialized) {
      _value =
          AppScope.of(context).scaleController.targetWeight ??
          defaultTargetGrams;
      _initialized = true;
    }
  }

  void _confirm() {
    AppScope.of(context).scaleController.setTarget(_value);
    Navigator.of(context).pop();
  }

  Future<void> _saveAsPreset() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<Preset>(
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(
          initial: Preset(name: '', targetWeightGrams: _value),
        ),
      ),
    );
    if (result != null && mounted) {
      await AppScope.of(context).presetController.add(result);
      messenger.showSnackBar(SnackBar(content: Text(l10n.presetSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setTargetTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            WeightStepper(
              value: _value,
              onChanged: (v) => setState(() => _value = v),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(l10n.confirm),
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.saveAsPreset),
              onPressed: _saveAsPreset,
            ),
          ],
        ),
      ),
    );
  }
}
