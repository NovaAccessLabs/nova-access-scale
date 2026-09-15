import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/preset.dart';
import '../util/grams.dart';
import '../widgets/weight_stepper.dart';

/// Create or edit a preset (name + target weight). Pops with the resulting
/// [Preset], or null if cancelled. Used for adding, editing/renaming, and
/// "save as preset" (which prefills the weight).
class PresetEditorScreen extends StatefulWidget {
  const PresetEditorScreen({this.initial, super.key});

  final Preset? initial;

  @override
  State<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<PresetEditorScreen> {
  late final TextEditingController _nameController;
  late int _weight;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _weight = widget.initial?.targetWeightGrams ?? defaultTargetGrams;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.presetNameRequired);
      // The error text appears silently for a screen-reader user — nothing
      // moves focus to it — so say why the save did not happen.
      AppScope.of(context).semanticsSpeech.announce(
        l10n.presetNameRequired,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      return;
    }
    Navigator.of(context).pop(Preset(name: name, targetWeightGrams: _weight));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.initial != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.editPreset : l10n.newPreset)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Standalone visible label above the field. A text field's label
            // is routed to the Android hintText (not content-desc), so a
            // separate, focusable label node is the reliable, screen-reader-
            // friendly pattern here — and it reads correctly with the typed
            // value (a content-desc on an editable would be read instead of it).
            Semantics(
              header: true,
              child: Text(
                l10n.presetNameField,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.presetNameExample,
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 32),
            Semantics(
              header: true,
              child: Text(
                l10n.presetWeightField,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            WeightStepper(
              value: _weight,
              onChanged: (v) => setState(() => _weight = v),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
