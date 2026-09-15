import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/preset.dart';
import '../theme/app_colors.dart';
import 'preset_editor_screen.dart';

/// Lists presets and supports create / rename / delete / select (PRD preset
/// features). When [selectionMode] is true, tapping a preset applies its target
/// and returns to the previous screen; otherwise tapping edits it.
class PresetManagementScreen extends StatelessWidget {
  const PresetManagementScreen({this.selectionMode = false, super.key});

  final bool selectionMode;

  Future<void> _add(BuildContext context) async {
    final result = await Navigator.of(context).push<Preset>(
      MaterialPageRoute(builder: (_) => const PresetEditorScreen()),
    );
    if (result != null && context.mounted) {
      await AppScope.of(context).presetController.add(result);
    }
  }

  Future<void> _edit(BuildContext context, int index, Preset preset) async {
    final result = await Navigator.of(context).push<Preset>(
      MaterialPageRoute(builder: (_) => PresetEditorScreen(initial: preset)),
    );
    if (result != null && context.mounted) {
      await AppScope.of(context).presetController.replaceAt(index, result);
    }
  }

  Future<void> _delete(BuildContext context, int index, Preset preset) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deletePresetTitle),
        content: Text(l10n.deletePresetMessage(preset.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppScope.of(context).presetController.removeAt(index);
    }
  }

  void _select(BuildContext context, Preset preset) {
    AppScope.of(context).scaleController.applyPreset(preset);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presetController = AppScope.of(context).presetController;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.presetsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addPreset,
            onPressed: () => _add(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: presetController,
          builder: (context, _) {
            final presets = presetController.presets;
            if (presets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.noPresets,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: presets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final preset = presets[index];
                return _PresetTile(
                  preset: preset,
                  selectionMode: selectionMode,
                  onTap: selectionMode
                      ? () => _select(context, preset)
                      : () => _edit(context, index, preset),
                  onEdit: () => _edit(context, index, preset),
                  onDelete: () => _delete(context, index, preset),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Preset preset;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final summary = l10n.presetSummary(preset.name, preset.targetWeightGrams);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              // Include the target in selection mode too, so a screen-reader
              // user hears the weight they are about to apply, not just the name.
              label: selectionMode
                  ? '${l10n.selectPreset(preset.name)}, '
                        '${l10n.targetValue(preset.targetWeightGrams)}'
                  : summary,
              onTap: onTap,
              child: ExcludeSemantics(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.targetValue(preset.targetWeightGrams),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Named, not just "Rename" / "Delete": in a list of presets a screen
          // reader would otherwise read the same two labels on every row, with
          // nothing to say which preset they act on.
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.renamePresetNamed(preset.name),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.warning),
            tooltip: l10n.deletePresetNamed(preset.name),
            onPressed: onDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
