import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/scale_controller.dart';
import '../feedback/target_feedback_engine.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../util/grams.dart';
import 'preset_management_screen.dart';
import 'settings_screen.dart';
import 'target_selector_screen.dart';

/// The weighing screen: live weight, target, status, and the primary actions
/// (tare, set target, choose preset). Shown once a scale is connected.
///
/// Feedback (cues, cadence, speech) should only run while this screen is the
/// visible top route, so it subscribes to the [RouteObserver] and pauses
/// feedback whenever another screen is pushed over it (e.g. the target
/// selector), resuming when it returns to the foreground.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  RouteObserver<ModalRoute<void>>? _routeObserver;
  ScaleController? _scaleController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _scaleController = scope.scaleController;
    _routeObserver = scope.routeObserver;
    final route = ModalRoute.of<void>(context);
    if (route != null) _routeObserver!.subscribe(this, route);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  /// Another screen was pushed over the weighing screen — pause feedback.
  @override
  void didPushNext() => _scaleController?.setFeedbackActive(false);

  /// Returned to the weighing screen — resume feedback.
  @override
  void didPopNext() => _scaleController?.setFeedbackActive(true);

  String _formatWeight(double grams) => grams.toStringAsFixed(1);

  /// The status line shown under the target, or null when there is nothing
  /// meaningful to show yet (no target, or not evaluated).
  String? _statusText(AppLocalizations l10n, ScaleController c) {
    final evaluation = c.evaluation;
    if (c.targetWeight == null || evaluation == null) return null;
    switch (evaluation.state) {
      case TargetState.approaching:
        return l10n.statusRemaining(formatGrams(evaluation.remainingGrams));
      case TargetState.reached:
        return l10n.statusTargetReached;
      case TargetState.over:
        return l10n.statusOverTarget(formatGrams(evaluation.overByGrams));
      case TargetState.idle:
        return null;
    }
  }

  Color _statusColor(BrandColors colors, ScaleController c) {
    switch (c.evaluation?.state) {
      case TargetState.reached:
        return colors.success;
      case TargetState.over:
        return colors.warning;
      default:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final controller = AppScope.of(context).scaleController;

    return Scaffold(
      // No actions: Settings is rarely used, so it sits at the end of the
      // body instead of the AppBar — otherwise it would be the first thing a
      // screen-reader user swipes past on every visit, ahead of Tare/target.
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final weightText = _formatWeight(controller.currentWeight);
            final target = controller.targetWeight;
            final status = _statusText(l10n, controller);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),

                // Live weight readout. Not a liveRegion: the scale streams
                // ~10 updates/second, which would flood TalkBack and end up
                // lagging the scale. The label stays so the value is read on
                // focus; only the settled value is announced (on a pause), with
                // the cadence earcons and haptics carrying the continuous
                // signal.
                Semantics(
                  label: l10n.liveWeight(weightText),
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text(
                          l10n.currentWeightLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        // FittedBox keeps the big readout from overflowing at
                        // large text sizes / long weights — it shrinks to fit
                        // only when needed.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _WeightReadout(
                            value: weightText,
                            unit: l10n.gramsUnit,
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Target + status. Also not a liveRegion: the "N grams
                // remaining" figure changes continuously while pouring. Reached
                // / over and the remaining figure are announced by the speech
                // engine on a pause (and by the distinct cues), so the values
                // here are read on focus without chattering.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: target == null
                      ? Text(
                          l10n.noTargetSet,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        )
                      : Column(
                          children: [
                            Text(
                              l10n.targetValue(target),
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (status != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                status,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: _statusColor(colors, controller),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Tare. An explicit Semantics node, not Tooltip(message:) and
                // not a bare Semantics(hint:) wrapper:
                // - Tooltip's message is only folded into the announced
                //   content when the node has no label of its own
                //   (AccessibilityBridge.createAccessibilityNodeInfo); this
                //   button already has one ("Tare"), so the hint would only
                //   reach TalkBack after a long press, not on normal focus.
                // - A plain `Semantics(hint: ...)` ancestor does not merge
                //   into FilledButton's own node either — verified via
                //   widget test, the merged node's hint came back empty
                //   (FilledButton draws a merge boundary). An explicit node
                //   with ExcludeSemantics on the child is the pattern this
                //   codebase already uses for the same reason elsewhere
                //   (_DeviceList, _ContactRow, WeightStepper's _StepButton).
                Semantics(
                  button: true,
                  label: l10n.tare,
                  hint: l10n.tareHint,
                  onTap: controller.tare,
                  child: ExcludeSemantics(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.exposure_zero),
                      label: Text(l10n.tare),
                      onPressed: controller.tare,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Target controls.
                OutlinedButton.icon(
                  icon: const Icon(Icons.adjust),
                  label: Text(l10n.setTarget),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TargetSelectorScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.bookmark_outline),
                  label: Text(l10n.choosePreset),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const PresetManagementScreen(selectionMode: true),
                    ),
                  ),
                ),
                if (controller.targetWeight == null &&
                    controller.hasLastTarget) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.history),
                    label: Text(l10n.startLastTarget),
                    onPressed: controller.startLastTarget,
                  ),
                ],

                // Last in the flow — rarely used, so it comes after every
                // weighing action rather than competing with them. Still
                // outlined (not plain text) so it has a visible boundary for
                // low-vision users scanning the screen, matching Set
                // target/Choose preset above.
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.settingsTitle),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The big live-weight readout: the number optically centered, with the unit
/// hanging off its right.
///
/// Centering the number and the unit *together* (a single RichText) pushes the
/// number left by the width of the unit, which reads as off-centre — the number
/// is the thing the eye tracks. An invisible twin of the unit on the left
/// balances the real one on the right, so the number lands dead centre while
/// the unit still sits beside it.
///
/// The twin is laid out (not painted), which keeps this safe inside the
/// FittedBox above: everything is measured, so nothing can overflow or clip.
class _WeightReadout extends StatelessWidget {
  const _WeightReadout({
    required this.value,
    required this.unit,
    required this.colors,
  });

  final String value;
  final String unit;
  final BrandColors colors;

  @override
  Widget build(BuildContext context) {
    // ~20% larger than the base weight readout for extra prominence of the
    // primary value.
    final valueStyle = AppTypography.weightReadout(
      colors,
    ).copyWith(fontSize: 86);
    final unitWidget = Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        unit,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          color: colors.textSecondary,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Same width as the real unit, never painted.
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: unitWidget,
        ),
        Text(value, style: valueStyle),
        unitWidget,
      ],
    );
  }
}
