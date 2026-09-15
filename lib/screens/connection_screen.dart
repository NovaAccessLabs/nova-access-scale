import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/scale_controller.dart';
import '../feedback/semantics_speech_output.dart';
import '../l10n/generated/app_localizations.dart';
import '../scale/scale_protocol.dart';
import '../theme/app_colors.dart';
import 'settings_screen.dart';

/// First screen of the main flow: connect to a scale before anything else —
/// connection precedes preset selection. Auto-starts a scan,
/// lists discovered (or demo) scales, and offers reconnect to the last device.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  // Not `final`: didChangeDependencies can run more than once (e.g. on a theme
  // or locale change), and re-assigning a `late final` would throw. The
  // controller is stable for the app's lifetime, so re-reading it is harmless.
  late ScaleController _controller;
  late SemanticsSpeechOutput _semanticsSpeech;

  int? _announcedDeviceCount;
  String? _announcedErrorKey;
  bool _announcedConnecting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AppScope.of(context).scaleController;
    _semanticsSpeech = AppScope.of(context).semanticsSpeech;
  }

  /// Announces how many scales the scan has turned up.
  ///
  /// The list simply appears, which is silent for a screen-reader user — a
  /// *newly inserted* live region is not read, only a changing one. Announcing
  /// it explicitly is the difference between "nothing happened" and "your scale
  /// is here", and this was the first thing a blind user noticed missing.
  void _announceDeviceCount(int count) {
    if (count == 0) {
      // Reset, so a later scan announces again. Without this, stopping a scan
      // that found one scale and starting another that finds the same one is
      // silent — the count never changes from the remembered value.
      _announcedDeviceCount = null;
      return;
    }
    if (count == _announcedDeviceCount) return;
    _announcedDeviceCount = count;
    final scope = AppScope.of(context);
    scope.semanticsSpeech.announce(
      AppLocalizations.of(context).scalesFound(count),
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  /// Announces a connection error the same way [_announceDeviceCount]
  /// announces a scan result: the banner below is a freshly-appearing
  /// `Container`, not a persistent node whose text changes, and this
  /// screen's own precedent is not to trust a live region for that case.
  /// Without this, a blind user hitting "Bluetooth is off" or "permission
  /// needed" gets total silence — no indication anything went wrong at all.
  void _announceError(String? key) {
    if (key == _announcedErrorKey) return;
    _announcedErrorKey = key;
    if (key == null) return;
    final l10n = AppLocalizations.of(context);
    final text = _errorText(l10n, key);
    if (text == null) return;
    AppScope.of(context).semanticsSpeech.announce(
      text,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  /// Announces the "Connecting…" transition for the same reason as
  /// [_announceError]: `_ConnectingIndicator` is a freshly-mounted subtree,
  /// not persistent text that changes, each time the scan button gives way
  /// to it.
  void _announceConnecting(bool connecting) {
    if (connecting == _announcedConnecting) return;
    _announcedConnecting = connecting;
    if (!connecting) return;
    AppScope.of(context).semanticsSpeech.announce(
      AppLocalizations.of(context).connecting,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  @override
  void initState() {
    super.initState();
    // Begin discovery as soon as the screen is shown.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.startScan(),
    );
  }

  @override
  void dispose() {
    _controller.stopScan();
    // The live region persists in the semantics tree until something
    // overwrites or clears it — same failure already found and fixed once
    // for SpeechRouter (a stale "Over target by 0.3 grams" was still the
    // first thing a TalkBack user met on this screen after disconnecting,
    // 2026-08-11). _announceConnecting/_announceError bypass SpeechRouter and
    // go straight to semanticsSpeech, so they need the same cleanup here:
    // without it, "Connecting…" or an old error outlives this screen and
    // greets the user on Home instead.
    unawaited(_semanticsSpeech.stop());
    super.dispose();
  }

  String? _errorText(AppLocalizations l10n, String? key) {
    switch (key) {
      case 'bluetoothOff':
        return l10n.bluetoothOff;
      case 'permission':
        return l10n.permissionNeeded;
      case 'failed':
      case 'unsupported':
        return l10n.connectionFailed;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      // No actions: Settings is rarely used, so it sits at the end of the
      // body instead of the AppBar — same reasoning, and the same place in
      // the flow, as on Home. A consistent "Settings is always last" position
      // matters more for a screen-reader user building a mental model of the
      // app than it does for a sighted one.
      appBar: AppBar(title: Text(l10n.connectTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final connecting =
                _controller.status == ScaleConnectionStatus.connecting;
            final devices = _controller.demoMode
                ? [_controller.demoDevice]
                : _controller.discoveredDevices;
            // After the frame, so the announcements land once their content
            // exists.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _announceDeviceCount(devices.length);
              _announceConnecting(connecting);
              _announceError(_controller.errorMessageKey);
            });
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.connectInstruction,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (connecting)
                  _ConnectingIndicator(label: l10n.connecting)
                else ...[
                  _ScanButton(
                    isScanning: _controller.isScanning,
                    scanLabel: l10n.scanForScales,
                    scanningLabel: l10n.scanning,
                    stopLabel: l10n.stopScanning,
                    onScan: _controller.startScan,
                    onStop: _controller.stopScan,
                  ),
                  const SizedBox(height: 24),
                  _DeviceList(
                    devices: devices,
                    isScanning: _controller.isScanning,
                    onConnect: _controller.connect,
                  ),
                ],
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final error = _errorText(l10n, _controller.errorMessageKey);
                    if (error == null) return const SizedBox.shrink();
                    // No Semantics(liveRegion: true) here: this Container is
                    // freshly mounted when an error first appears, not
                    // persistent text that changes, and _announceError above
                    // handles telling the user proactively (this screen's own
                    // established pattern, per _announceDeviceCount). The
                    // plain Text below is still fully readable on manual
                    // swipe — only the auto-announcement goes through
                    // semanticsSpeech instead.
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.warning, width: 1.5),
                      ),
                      child: Text(
                        error,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: colors.warning),
                      ),
                    );
                  },
                ),

                // Last in the flow — rarely used, so it comes after
                // scanning/connecting rather than competing with them. Still
                // outlined (not plain text) so it has a visible boundary for
                // low-vision users scanning the screen, matching Home.
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

class _ConnectingIndicator extends StatelessWidget {
  const _ConnectingIndicator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // No liveRegion here: this widget is freshly mounted when connecting
    // starts, not persistent text that changes, and _announceConnecting on
    // ConnectionScreen handles telling the user proactively instead (see its
    // doc comment). This Semantics node is still fully readable on manual
    // swipe — label is set explicitly, not inherited, because ExcludeSemantics
    // below hides the child Text from contributing its own.
    return Semantics(
      label: label,
      // Without this the node's label and the child Text carry the same string,
      // so a screen reader reads "Connecting…" twice.
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.isScanning,
    required this.scanLabel,
    required this.scanningLabel,
    required this.stopLabel,
    required this.onScan,
    required this.onStop,
  });

  final bool isScanning;
  final String scanLabel;
  final String scanningLabel;
  final String stopLabel;
  final VoidCallback onScan;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return FilledButton.icon(
        icon: const Icon(Icons.stop),
        label: Text(stopLabel),
        onPressed: onStop,
      );
    }
    return FilledButton.icon(
      icon: const Icon(Icons.bluetooth_searching),
      label: Text(scanLabel),
      onPressed: onScan,
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({
    required this.devices,
    required this.isScanning,
    required this.onConnect,
  });

  final List<ScaleDevice> devices;
  final bool isScanning;
  final ValueChanged<ScaleDevice> onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          isScanning ? l10n.scanning : l10n.noScalesFound,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A sibling heading, not a container wrapping the buttons: wrapping
        // merged the heading into the first device, so the tree exposed one
        // node reading "Available scales, Connect to MY_SCALE" and the heading
        // was not separately navigable.
        Semantics(
          header: true,
          // container: true is what actually makes this a node of its own.
          // Without it a Semantics widget annotates the nearest enclosing node,
          // so the heading and the first device button merged into a single
          // clickable "Available scales, Connect to MY_SCALE".
          container: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.availableScales,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final device in devices)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  button: true,
                  container: true,
                  label: l10n.connectToDevice(device.name),
                  onTap: () => onConnect(device),
                  child: ExcludeSemantics(
                    child: Material(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onConnect(device),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.scale_outlined,
                                color: colors.accentDecorative,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  device.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
