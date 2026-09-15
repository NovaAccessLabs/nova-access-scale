import 'dart:async';

import '../models/feedback_mode.dart';
import 'feedback_outputs.dart';
import 'stability_detector.dart';
import 'target_feedback_engine.dart';

/// Builds the localized speech phrase for an evaluation, or null if nothing
/// should be spoken. Supplied by the app layer (which owns localization), so
/// this file stays free of l10n imports.
typedef AnnouncementBuilder = String? Function(FeedbackEvaluation evaluation);

/// Turns a stream of weight samples into coordinated feedback.
///
/// Responsibilities:
///  * Evaluate each sample with [TargetFeedbackEngine].
///  * Emit non-verbal cues through the [PulseFeedbackOutput] channels selected
///    by the current [FeedbackMode]: approach pulses on the cadence while
///    approaching, and a distinct one-shot cue on entering the reached / over
///    states.
///  * Emit pause-gated speech: when [StabilityDetector] reports a pause and
///    speech is enabled, announce the grams remaining / reached / over.
///
/// All output goes through injected interfaces, so the decision logic is
/// testable with fakes.
class FeedbackCoordinator {
  FeedbackCoordinator({
    required this.audio,
    required this.haptic,
    required this.speech,
    this.engine = const TargetFeedbackEngine(),
    StabilityDetector? stabilityDetector,
  }) : _stability = stabilityDetector ?? StabilityDetector();

  final PulseFeedbackOutput audio;
  final PulseFeedbackOutput haptic;
  final SpeechOutput speech;
  final TargetFeedbackEngine engine;
  final StabilityDetector _stability;

  /// Notified when the evaluation changes *without* a new weight sample: a
  /// pending reached/over transition confirmed by its own timer because the
  /// scale stopped streaming. Sample-driven changes are returned from
  /// [onWeightSample] instead, so this is the only path the UI cannot see by
  /// watching that return value.
  void Function(FeedbackEvaluation evaluation)? onEvaluationChanged;

  // Configuration, kept in sync by the controller.
  FeedbackMode mode = FeedbackMode.audio;
  bool speechEnabled = true;
  String languageCode = 'en';
  AnnouncementBuilder? announcementBuilder;

  /// Extra delay after a pause is detected before the grams-remaining is
  /// spoken, so the announced figure reflects a *settled* reading: a flickery
  /// scale can keep drifting for a moment after it first holds still. The
  /// latest reading at announce time is used. Set to [Duration.zero] to speak
  /// immediately on the pause.
  Duration announceSettleDelay = const Duration(milliseconds: 1000);

  /// How long the weight must stay within the reached band before it is
  /// reported as reached (cue, speech, and on-screen state). A flickery scale
  /// can momentarily touch the target; this debounce ignores brief touches.
  /// Set to [Duration.zero] to react on the first reached sample.
  Duration reachedConfirmDelay = const Duration(milliseconds: 1000);

  /// How long the weight must stay over the target before it is reported as
  /// over (cue, speech, and the on-screen state). A flickery scale can briefly
  /// spike past the target; this debounce ignores momentary overshoots. Set to
  /// [Duration.zero] to react on the first over sample.
  Duration overConfirmDelay = const Duration(milliseconds: 1000);

  int? _target;
  TargetState _lastState = TargetState.idle;
  Duration? _currentCadence;
  Timer? _pulseTimer;
  String? _lastSpoken;
  final Stopwatch _clock = Stopwatch()..start();

  // Pending grams-remaining announcement, gated by [announceSettleDelay].
  Duration? _announceDueAt;
  double? _pendingAnchorGrams;

  // Debounce of entry into reached/over: the candidate state and the time it
  // becomes confirmed. Until then the step-below state is reported, so a brief
  // flicker into reached/over doesn't drive the cues, speech, or the display.
  TargetState? _pendingState;
  Duration? _confirmAt;

  // Backstop for the debounce above. Confirmation is normally driven by the
  // next weight sample, but a scale that stops streaming once the weight is
  // stable (common power-saving behavior) can go quiet at exactly the moment a
  // transition is pending — leaving the user on the pre-transition reading with
  // no over-target warning. This timer commits the pending state on its own.
  Timer? _confirmTimer;
  double? _lastGrams;

  FeedbackEvaluation? lastEvaluation;

  /// Sets (or clears) the active target and resets transient feedback state.
  void setTarget(int? target) {
    _target = target;
    _stability.reset();
    _resetPulse();
    _clearPendingAnnouncement();
    _clearPendingState();
    _lastState = TargetState.idle;
    _lastSpoken = null;
    lastEvaluation = null;
  }

  void updateConfig({
    FeedbackMode? mode,
    bool? speechEnabled,
    String? languageCode,
  }) {
    if (mode != null) this.mode = mode;
    if (languageCode != null) this.languageCode = languageCode;
    if (speechEnabled != null) {
      this.speechEnabled = speechEnabled;
      if (!speechEnabled) speech.stop();
    }
  }

  /// Processes one weight sample (grams). [elapsed] drives pause timing and
  /// defaults to the internal monotonic clock; tests pass it explicitly.
  FeedbackEvaluation onWeightSample(double grams, {Duration? elapsed}) {
    final target = _target;
    final now = elapsed ?? _clock.elapsed;
    _lastGrams = grams;
    final raw = engine.evaluate(
      currentWeight: grams,
      targetWeightGrams: target ?? 0,
    );
    // Debounce reached/over at the source so the returned evaluation — which
    // also drives the on-screen status and the screen reader — matches the cues.
    final evaluation = _debounce(raw, now, grams);
    lastEvaluation = evaluation;

    _handleStateTransition(evaluation);

    // Grams-remaining is spoken only when the user pauses (so it doesn't chatter
    // while pouring). Reached / over are spoken immediately on transition above,
    // and re-confirmed here on a pause; the dedup in [_speak] stops repeats.
    if (target != null && target > 0) {
      _handlePauseAnnouncement(grams, now, evaluation);
    }

    return evaluation;
  }

  /// Debounces entry into `reached` and `over`: a flickery scale can briefly
  /// touch the target band or spike past it. A newly-entered reached/over state
  /// must persist for its confirm delay before it is reported; until then the
  /// step-below state is returned, so the cues, speech, *and* the on-screen
  /// state all hold off. Approaching/idle are reported immediately.
  FeedbackEvaluation _debounce(
    FeedbackEvaluation raw,
    Duration now,
    double grams,
  ) {
    final delay = switch (raw.state) {
      TargetState.reached => reachedConfirmDelay,
      TargetState.over => overConfirmDelay,
      _ => Duration.zero,
    };

    // Already the committed state, or a state we never debounce -> pass through.
    if (raw.state == _lastState || delay <= Duration.zero) {
      _clearPendingState();
      return raw;
    }

    if (_pendingState != raw.state) {
      _pendingState = raw.state;
      _confirmAt = now + delay;
      // Arm the backstop in case this is the last sample we ever get.
      _confirmTimer?.cancel();
      _confirmTimer = Timer(delay, _confirmPendingState);
    }
    if (now >= _confirmAt!) {
      _clearPendingState();
      return raw; // persisted long enough -> confirmed
    }
    // Still confirming: keep reporting the last committed evaluation. This is
    // why a normal pour works — passing briefly through the reached band on the
    // way to over holds the prior "approaching", so neither reached nor over is
    // reported until one actually persists. Falls back to a neutral approaching
    // view only before anything has been committed (e.g. the very first sample).
    return lastEvaluation ?? _approachingView(grams);
  }

  /// A neutral "approaching" view, used only before any state has been committed
  /// so a debounced first sample never reports reached/over immediately.
  FeedbackEvaluation _approachingView(double grams) {
    final remaining = ((_target ?? 0) - grams).clamp(0.0, double.infinity);
    return FeedbackEvaluation(
      state: TargetState.approaching,
      cadence: engine.maxInterval,
      remainingGrams: remaining,
      overByGrams: 0,
    );
  }

  /// Speaks the grams-remaining on a pause, but only after [announceSettleDelay]
  /// so the figure reflects a settled reading. The latest reading at announce
  /// time is used; a pending announcement is dropped if the weight moves beyond
  /// the stability tolerance (the user resumed pouring) before the delay passes.
  void _handlePauseAnnouncement(
    double grams,
    Duration now,
    FeedbackEvaluation evaluation,
  ) {
    if (_stability.addSample(grams, now)) {
      if (announceSettleDelay <= Duration.zero) {
        _speak(evaluation);
      } else {
        _announceDueAt = now + announceSettleDelay;
        _pendingAnchorGrams = grams;
      }
      return;
    }

    final dueAt = _announceDueAt;
    final anchor = _pendingAnchorGrams;
    if (dueAt == null || anchor == null) return;

    if ((grams - anchor).abs() > _stability.toleranceGrams) {
      _clearPendingAnnouncement(); // moved again -> stale reading, drop it
    } else if (now >= dueAt) {
      _clearPendingAnnouncement();
      _speak(evaluation); // latest, settled reading
    }
  }

  void _clearPendingAnnouncement() {
    _announceDueAt = null;
    _pendingAnchorGrams = null;
  }

  void _clearPendingState() {
    _pendingState = null;
    _confirmAt = null;
    _confirmTimer?.cancel();
    _confirmTimer = null;
  }

  /// Commits a reached/over transition that no further sample arrived to
  /// confirm, using the last weight seen. Without this, a scale that goes quiet
  /// at the transition would leave the user on the pre-transition reading — for
  /// a blind user, "at target" while actually well over it.
  void _confirmPendingState() {
    final grams = _lastGrams;
    if (_pendingState == null || grams == null) return;
    _clearPendingState();

    final evaluation = engine.evaluate(
      currentWeight: grams,
      targetWeightGrams: _target ?? 0,
    );
    lastEvaluation = evaluation;
    _handleStateTransition(evaluation);
    onEvaluationChanged?.call(evaluation);
  }

  void _handleStateTransition(FeedbackEvaluation evaluation) {
    _currentCadence = evaluation.cadence;
    final state = evaluation.state;
    if (state == _lastState) return;

    switch (state) {
      case TargetState.approaching:
        _startPulseLoop();
      case TargetState.reached:
        _resetPulse();
        _clearPendingAnnouncement(); // a deferred "remaining" would be stale now
        _emitCue((output) => output.reached());
        _speak(evaluation); // announce the moment the target is reached
      case TargetState.over:
        _resetPulse();
        _clearPendingAnnouncement();
        _emitCue((output) => output.overTarget());
        _speak(evaluation); // announce the moment we go over
      case TargetState.idle:
        _resetPulse();
        _clearPendingAnnouncement();
    }
    _lastState = state;
  }

  /// Speaks the localized phrase for [evaluation], if speech is on and available.
  /// Skips a phrase identical to the last one spoken so the immediate reached /
  /// over announcement isn't repeated by the pause that follows it.
  void _speak(FeedbackEvaluation evaluation) {
    if (!speechEnabled || !speech.isAvailable) return;
    final text = announcementBuilder?.call(evaluation);
    if (text == null || text.isEmpty || text == _lastSpoken) return;
    _lastSpoken = text;
    speech.announce(text, languageCode: languageCode);
  }

  void _startPulseLoop() {
    _resetPulse();
    void schedule() {
      final cadence = _currentCadence;
      if (cadence == null) return;
      _pulseTimer = Timer(cadence, () {
        _emitCue((output) => output.approachPulse());
        schedule(); // re-reads _currentCadence, so cadence adapts each cycle
      });
    }

    schedule();
  }

  void _emitCue(Future<void> Function(PulseFeedbackOutput) action) {
    if (mode.usesAudio) action(audio);
    if (mode.usesVibration) action(haptic);
  }

  void _resetPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  /// Stops all active feedback (e.g. on disconnect).
  Future<void> stop() async {
    _resetPulse();
    _clearPendingAnnouncement();
    _clearPendingState();
    await speech.stop();
    _stability.reset();
    _lastState = TargetState.idle;
    _lastSpoken = null;
  }

  void dispose() {
    _resetPulse();
    _clearPendingAnnouncement();
    _clearPendingState();
    _clock.stop();
  }
}
