import 'dart:async';

import 'package:flutter/foundation.dart';

import '../feedback/feedback_coordinator.dart';
import '../feedback/target_feedback_engine.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/preset.dart';
import '../repositories/settings_repository.dart';
import '../scale/mock_scale_protocol.dart';
import '../scale/scale_ble_service.dart';
import '../scale/scale_protocol.dart';
import '../scale/scale_protocol_registry.dart';
import '../util/grams.dart';
import 'settings_controller.dart';

/// The central controller for connecting to a scale, streaming weight, managing
/// the target, and driving feedback.
///
/// UI never touches BLE or protocols directly — it observes this controller and
/// calls its commands. Scale-specific behavior lives behind [ScaleProtocol].
class ScaleController extends ChangeNotifier {
  ScaleController({
    required SettingsController settingsController,
    required SettingsRepository settingsRepository,
    required ScaleBleService bleService,
    required ScaleProtocolRegistry registry,
    required FeedbackCoordinator coordinator,
    MockScaleProtocol Function()? mockFactory,
  }) : _settingsController = settingsController,
       _settingsRepository = settingsRepository,
       _bleService = bleService,
       _registry = registry,
       _coordinator = coordinator,
       _mockFactory = mockFactory ?? _defaultMockFactory;

  static MockScaleProtocol _defaultMockFactory() =>
      MockScaleProtocol(autoRamp: true);

  final SettingsController _settingsController;
  final SettingsRepository _settingsRepository;
  final ScaleBleService _bleService;
  final ScaleProtocolRegistry _registry;
  final FeedbackCoordinator _coordinator;
  final MockScaleProtocol Function() _mockFactory;

  ScaleProtocol? _protocol;
  StreamSubscription<double>? _weightSub;
  StreamSubscription<ScaleConnectionStatus>? _statusSub;
  StreamSubscription<List<ScaleDevice>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;

  bool _disposed = false;
  bool _demoMode = false;
  bool _feedbackActive = true;
  String _demoDeviceName = 'Demo scale';

  // --- Observable state ---
  ScaleConnectionStatus _status = ScaleConnectionStatus.disconnected;
  ScaleDevice? _device;
  double _currentWeight = 0;
  int? _targetWeight;
  FeedbackEvaluation? _evaluation;
  List<ScaleDevice> _discovered = const [];
  bool _isScanning = false;
  String? _errorMessageKey;

  ScaleConnectionStatus get status => _status;
  ScaleDevice? get device => _device;
  bool get isConnected => _status == ScaleConnectionStatus.connected;
  double get currentWeight => _currentWeight;
  int? get targetWeight => _targetWeight;
  FeedbackEvaluation? get evaluation => _evaluation;
  List<ScaleDevice> get discoveredDevices => _discovered;
  bool get isScanning => _isScanning;
  bool get demoMode => _settingsController.settings.demoMode;

  /// A connection-related error to surface, as a key the UI maps to a localized
  /// message: 'failed', 'unsupported', 'bluetoothOff', 'permission'.
  String? get errorMessageKey => _errorMessageKey;

  /// Whether a previous device can be reconnected to.
  bool get canReconnect => _settingsRepository.loadLastDeviceId() != null;

  /// Whether a previously used target exists (for "Start last target").
  bool get hasLastTarget => _settingsRepository.loadLastTarget() != null;

  /// The simulated device shown in demo mode.
  ScaleDevice get demoDevice =>
      ScaleDevice(id: MockScaleProtocol.deviceId, name: _demoDeviceName);

  void init() {
    _demoMode = _settingsController.settings.demoMode;
    // A reached/over transition can be confirmed by the coordinator's own timer
    // when the scale stops streaming, with no sample to return it to us.
    _coordinator.onEvaluationChanged = (evaluation) {
      if (!_feedbackActive) return;
      _evaluation = evaluation;
      _safeNotify();
    };
    _coordinator.updateConfig(
      mode: _settingsController.settings.feedbackMode,
      speechEnabled: _settingsController.settings.speechEnabled,
    );
    _targetWeight = _settingsRepository.loadLastTarget();
    _settingsController.addListener(_onSettingsChanged);

    final settings = _settingsController.settings;
    if (!settings.demoMode && settings.autoReconnect) {
      final id = _settingsRepository.loadLastDeviceId();
      final name = _settingsRepository.loadLastDeviceName();
      if (id != null && name != null) {
        unawaited(
          connect(ScaleDevice(id: id, name: name), tareOnConnect: true),
        );
      }
    }
  }

  /// Wires localized announcement text and the demo device name. Called from
  /// the widget tree whenever localizations resolve/change.
  void setLocalization(AppLocalizations l10n, String languageCode) {
    _demoDeviceName = l10n.demoScaleName;
    _coordinator.announcementBuilder = (evaluation) {
      switch (evaluation.state) {
        case TargetState.approaching:
          return l10n.announceRemaining(formatGrams(evaluation.remainingGrams));
        case TargetState.reached:
          return l10n.announceTargetReached;
        case TargetState.over:
          return l10n.announceOverTarget(formatGrams(evaluation.overByGrams));
        case TargetState.idle:
          return null;
      }
    };
    _coordinator.updateConfig(languageCode: languageCode);
  }

  void _onSettingsChanged() {
    final settings = _settingsController.settings;
    _coordinator.updateConfig(
      mode: settings.feedbackMode,
      speechEnabled: settings.speechEnabled,
    );
    // Switching between demo and real changes the connection backend, so drop
    // any current connection.
    if (settings.demoMode != _demoMode) {
      _demoMode = settings.demoMode;
      unawaited(disconnect());
      _discovered = const [];
    }
    _safeNotify();
  }

  // --- Scanning ---

  Future<void> startScan() async {
    _errorMessageKey = null;
    if (_settingsController.settings.demoMode) {
      _discovered = [demoDevice];
      _isScanning = false;
      _safeNotify();
      return;
    }
    // A connect may already be under way — e.g. auto-reconnect on launch
    // (init()) fires connect() before ConnectionScreen even mounts, and its
    // initState() calls startScan() unconditionally. Scanning while a GATT
    // connect is in flight is the concurrent scan+connect pattern
    // universal_ble's own docs warn against, and was observed to destabilize
    // the connection on a real device. connect() already calls stopScan()
    // itself before it starts, so skipping here doesn't lose a stop either
    // way — it just avoids starting a new scan mid-connect.
    if (_status == ScaleConnectionStatus.connecting) return;
    await _scanSub?.cancel();
    await _isScanningSub?.cancel();
    // Drop whatever the previous scan found before starting a new one.
    // `discoveredScales` only emits when it *finds* something, so without this
    // a scale that has since been switched off keeps its stale row in the list
    // forever: the fresh subscription simply never emits, and `_discovered`
    // holds the old value. Clearing here means the list always reflects the
    // current scan, and the screen-reader count announcement resets with it.
    _discovered = const [];
    _safeNotify();
    _scanSub = _bleService.discoveredScales.listen((devices) {
      _discovered = devices;
      // Finding a device proves Bluetooth is available and permitted, so clear
      // any earlier (often transient) scan error left over from startup.
      if (devices.isNotEmpty) _errorMessageKey = null;
      _safeNotify();
    });
    _isScanningSub = _bleService.isScanning.listen((scanning) {
      _isScanning = scanning;
      // A scan that actually starts means there was no permission problem.
      if (scanning) _errorMessageKey = null;
      _safeNotify();
    });
    try {
      await _bleService.startScan();
    } catch (_) {
      // Only reached if the adapter never became ready (Bluetooth off or
      // permission denied) — not on the transient startup state.
      _errorMessageKey = _bleService.isAdapterOff
          ? 'bluetoothOff'
          : 'permission';
      _safeNotify();
    }
  }

  Future<void> stopScan() async {
    if (!_settingsController.settings.demoMode) {
      await _bleService.stopScan();
    }
    _isScanning = false;
    _safeNotify();
  }

  // --- Connection ---

  Future<void> connect(ScaleDevice device, {bool tareOnConnect = false}) async {
    _errorMessageKey = null;
    await stopScan();
    await _teardownProtocol();

    final isDemo = device.id == MockScaleProtocol.deviceId;
    final protocol = isDemo
        ? _mockFactory()
        : _registry.createForName(device.name);
    if (protocol == null) {
      _errorMessageKey = 'unsupported';
      _status = ScaleConnectionStatus.error;
      _safeNotify();
      return;
    }

    _protocol = protocol;
    _statusSub = protocol.statusStream.listen(_onStatus);
    _weightSub = protocol.weightStream.listen(_onWeight);

    _device = device;
    _status = ScaleConnectionStatus.connecting;
    _safeNotify();

    try {
      await protocol.connect(device);
      if (!isDemo) {
        await _settingsRepository.saveLastDevice(device.id, device.name);
      }
      _coordinator.setTarget(_targetWeight);
      // Auto-tare after an automatic reconnect (e.g. on launch) so the user
      // starts from zero without having to tare manually. The protocol reports
      // connected only once it is ready, so the tare command lands.
      if (tareOnConnect) {
        await protocol.tare();
      }
    } catch (_) {
      _errorMessageKey = 'failed';
      _status = ScaleConnectionStatus.error;
      await _teardownProtocol();
      _safeNotify();
    }
  }

  Future<void> disconnect() async {
    await _protocol?.disconnect();
    await _coordinator.stop();
    await _teardownProtocol();
    _status = ScaleConnectionStatus.disconnected;
    _device = null;
    _evaluation = null;
    _safeNotify();
  }

  Future<void> tare() async {
    await _protocol?.tare();
  }

  /// Enables or disables live feedback (cues, cadence, speech). Feedback should
  /// run only on the weighing screen, so it is paused while another screen
  /// (target selector, presets, settings) is open. Weight still streams to keep
  /// the display current; it just stops driving the feedback channels.
  void setFeedbackActive(bool active) {
    if (_feedbackActive == active) return;
    _feedbackActive = active;
    if (active) {
      // Resume: refresh feedback + status from the latest weight.
      _evaluation = _coordinator.onWeightSample(_currentWeight);
    } else {
      // Pause: stop any in-flight pulses/speech at once.
      unawaited(_coordinator.stop());
    }
    _safeNotify();
  }

  // --- Target & presets ---

  Future<void> setTarget(int grams) async {
    if (grams < 1) return;
    _targetWeight = grams;
    _coordinator.setTarget(grams);
    // Re-evaluate immediately so feedback reflects the new target at once — but
    // only if feedback is active (e.g. not while the target selector is open;
    // resuming on return to the weighing screen will re-evaluate then).
    if (_feedbackActive) {
      _evaluation = _coordinator.onWeightSample(_currentWeight);
    }
    _safeNotify();
    await _settingsRepository.saveLastTarget(grams);
  }

  void clearTarget() {
    _targetWeight = null;
    _coordinator.setTarget(null);
    _evaluation = null;
    _safeNotify();
  }

  Future<void> startLastTarget() async {
    final last = _settingsRepository.loadLastTarget();
    if (last != null) await setTarget(last);
  }

  Future<void> applyPreset(Preset preset) =>
      setTarget(preset.targetWeightGrams);

  // --- Internal ---

  void _onStatus(ScaleConnectionStatus status) {
    _status = status;
    if (status == ScaleConnectionStatus.disconnected) {
      unawaited(_coordinator.stop());
    }
    _safeNotify();
  }

  void _onWeight(double grams) {
    _currentWeight = grams;
    // Keep the display current always, but only drive feedback when active.
    if (_feedbackActive) {
      _evaluation = _coordinator.onWeightSample(grams);
    }
    _safeNotify();
  }

  Future<void> _teardownProtocol() async {
    await _weightSub?.cancel();
    await _statusSub?.cancel();
    _weightSub = null;
    _statusSub = null;
    final protocol = _protocol;
    _protocol = null;
    await protocol?.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settingsController.removeListener(_onSettingsChanged);
    unawaited(_scanSub?.cancel());
    unawaited(_isScanningSub?.cancel());
    unawaited(_teardownProtocol());
    _coordinator.dispose();
    super.dispose();
  }
}
