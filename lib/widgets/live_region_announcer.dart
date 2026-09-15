import 'package:flutter/material.dart';

import '../feedback/semantics_speech_output.dart';

/// Renders [SemanticsSpeechOutput]'s current message as a zero-size live region
/// so the platform screen reader reads it aloud.
///
/// Wraps the whole app so the region is mounted for the app's lifetime: an
/// announcement can be triggered from anywhere, and a region that came and went
/// with a screen would miss them. It draws nothing and takes no space; only the
/// semantics tree sees it.
///
/// Live region, not an announcement event: see SemanticsSpeechOutput for why
/// (`sendAnnouncement` is deprecated on Android 16 and was verified silent).
class LiveRegionAnnouncer extends StatefulWidget {
  const LiveRegionAnnouncer({
    required this.output,
    required this.child,
    super.key,
  });

  final SemanticsSpeechOutput output;
  final Widget child;

  @override
  State<LiveRegionAnnouncer> createState() => _LiveRegionAnnouncerState();
}

class _LiveRegionAnnouncerState extends State<LiveRegionAnnouncer> {
  /// Small enough to be invisible, large enough that the platform does not
  /// treat the semantics node as an empty (and therefore skippable) rect.
  static const double _hitSize = 1;

  @override
  void initState() {
    super.initState();
    // Tells the output a renderer exists; until then it reports itself
    // unavailable and the router speaks with the app's own voice instead.
    widget.output.attachRenderer();
  }

  @override
  void didUpdateWidget(LiveRegionAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.output != widget.output) {
      oldWidget.output.detachRenderer();
      widget.output.attachRenderer();
    }
  }

  @override
  void dispose() {
    widget.output.detachRenderer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // passthrough, not the default loose fit: this wraps the whole app, and
      // loose constraints could change how the Navigator below sizes itself.
      // The incoming constraints reach the child exactly as they would without
      // this widget in the tree.
      fit: StackFit.passthrough,
      children: [
        widget.child,
        // Unpainted, but it MUST occupy a real rect: Android skips accessibility
        // nodes with empty bounds as invisible, so a zero-size node is never
        // announced (verified on-device 2026-08-11 — TalkBack said nothing).
        // 1x1 is invisible in practice while keeping the node reachable.
        Positioned(
          left: 0,
          top: 0,
          width: _hitSize,
          height: _hitSize,
          child: IgnorePointer(
            child: ValueListenableBuilder<String?>(
              valueListenable: widget.output.message,
              builder: (context, message, _) {
                if (message == null || message.isEmpty) {
                  return const SizedBox(width: _hitSize, height: _hitSize);
                }
                return Semantics(
                  container: true,
                  liveRegion: true,
                  label: message,
                  child: const SizedBox(width: _hitSize, height: _hitSize),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
