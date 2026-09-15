import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feedback_mode.dart';
import '../models/speech_output_mode.dart';
import '../theme/app_colors.dart';
import '../widgets/labeled_option_picker.dart';

/// Settings. Option groups use large pill toggles
/// (no sliders, no radios) with clear semantic labels; binary settings stay as
/// switches. About and Contact are shown inline.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _contactEmail = 'novaaccesslabs@gmail.com';
  static const String _instagramHandle = '@novaaccesslabs';
  static const String _instagramUrl =
      'https://www.instagram.com/novaaccesslabs/';
  static const String _koFiHandle = 'ko-fi.com/novaaccesslabs';
  static const String _koFiUrl = 'https://ko-fi.com/novaaccesslabs';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppScope.of(context).settingsController;
    // A real screen reader talking over the app's own "Both" voice is the one
    // genuinely illogical combination — Screen reader vs. App voice both stay
    // meaningful choices either way (App voice is a deliberate override, not a
    // redundant one: it always uses the app's own TTS regardless of screen
    // reader state, which some users prefer over waiting on the screen
    // reader's own announcement queue). See lib/feedback/speech_router.dart.
    final screenReaderActive = MediaQuery.of(context).accessibleNavigation;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final s = controller.settings;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                LabeledOptionPicker<FeedbackMode>(
                  label: l10n.feedbackSectionTitle,
                  selected: s.feedbackMode,
                  // Confirm the choice on the very channels it enables, so the
                  // user can feel/hear it is on without starting a weigh: a buzz
                  // for vibration modes, a short earcon for sound modes.
                  onChanged: (m) {
                    if (m.usesVibration) {
                      HapticFeedback.mediumImpact();
                    }
                    if (m.usesAudio) {
                      AppScope.of(context).audioFeedback.approachPulse();
                    }
                    controller.setFeedbackMode(m);
                  },
                  options: [
                    PickerOption(FeedbackMode.audio, l10n.feedbackModeAudio),
                    PickerOption(
                      FeedbackMode.vibration,
                      l10n.feedbackModeVibration,
                    ),
                    PickerOption(
                      FeedbackMode.audioVibration,
                      l10n.feedbackModeAudioVibration,
                    ),
                  ],
                ),
                SwitchListTile(
                  title: Text(l10n.speechEnabled),
                  subtitle: Text(l10n.speechEnabledDescription),
                  value: s.speechEnabled,
                  onChanged: controller.setSpeechEnabled,
                  contentPadding: EdgeInsets.zero,
                ),
                // Which voice speaks those announcements — only a live choice
                // while a screen reader is active (see SpeechRouter's routing
                // table: with none running, every mode already resolves to
                // the app's own voice, so there is nothing to pick and the
                // section is omitted rather than stating the obvious).
                if (s.speechEnabled && screenReaderActive) ...[
                  const SizedBox(height: 12),
                  LabeledOptionPicker<SpeechOutputMode>(
                    label: l10n.speechOutput,
                    selected: s.speechOutputMode,
                    onChanged: controller.setSpeechOutputMode,
                    options: [
                      PickerOption(
                        SpeechOutputMode.screenReader,
                        l10n.speechOutputScreenReader,
                      ),
                      PickerOption(
                        SpeechOutputMode.appVoice,
                        l10n.speechOutputAppVoice,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.speechOutputDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],

                _SectionHeader(l10n.appearanceSectionTitle),
                SwitchListTile(
                  title: Text(l10n.highContrast),
                  subtitle: Text(l10n.highContrastDescription),
                  value: s.highContrast,
                  onChanged: controller.setHighContrast,
                  contentPadding: EdgeInsets.zero,
                ),

                _SectionHeader(l10n.connectionSectionTitle),
                SwitchListTile(
                  title: Text(l10n.autoReconnect),
                  subtitle: Text(l10n.autoReconnectDescription),
                  value: s.autoReconnect,
                  onChanged: controller.setAutoReconnect,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: Text(l10n.demoMode),
                  subtitle: Text(l10n.demoModeDescription),
                  value: s.demoMode,
                  onChanged: controller.setDemoMode,
                  contentPadding: EdgeInsets.zero,
                ),

                _SectionHeader(l10n.aboutTitle),
                _AboutNote(l10n.aboutBody),

                _SectionHeader(l10n.contactSectionTitle),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.contactIntro,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                _ContactRow(
                  icon: Icons.mail_outline,
                  label: l10n.contactEmailLabel,
                  value: _contactEmail,
                  hint: l10n.contactEmailHint,
                  target: Uri(scheme: 'mailto', path: _contactEmail),
                ),
                _ContactRow(
                  icon: Icons.camera_alt_outlined,
                  label: l10n.contactInstagramLabel,
                  value: _instagramHandle,
                  hint: l10n.contactInstagramHint,
                  target: Uri.parse(_instagramUrl),
                ),
                // A heart, not a coffee cup: this app weighs coffee, so a cup
                // icon here would read as a feature rather than a donation.
                _ContactRow(
                  icon: Icons.favorite_outline,
                  label: l10n.contactSupportLabel,
                  value: _koFiHandle,
                  hint: l10n.contactSupportHint,
                  target: Uri.parse(_koFiUrl),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: context.colors.accentText),
        ),
      ),
    );
  }
}

/// A short descriptive note about the app, in a bordered surface box.
class _AboutNote extends StatelessWidget {
  const _AboutNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

/// A tappable contact line: a caption label above a link value that hands off
/// to the OS's own app ([target] — a `mailto:` for email, an Instagram URL).
/// The whole row is one screen-reader button announced as e.g.
/// "Email, novaaccesslabs@gmail.com" with a hint of what it opens; the leading
/// [icon] marks it as actionable so color is never the only cue.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.target,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final Uri target;

  Future<void> _launch(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorText = AppLocalizations.of(context).couldNotOpenLink;
    var ok = false;
    try {
      ok = await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$label, $value',
      hint: hint,
      onTap: () => _launch(context),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => _launch(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, color: c.accentText),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: c.accentText,
                          decoration: TextDecoration.underline,
                          decorationColor: c.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
