// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NovaAccessScale';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get gramsUnit => 'g';

  @override
  String get connectTitle => 'Connect to scale';

  @override
  String get connectInstruction => 'Connect your scale to begin.';

  @override
  String get scanForScales => 'Scan for scales';

  @override
  String get scanning => 'Scanning…';

  @override
  String get stopScanning => 'Stop scanning';

  @override
  String get noScalesFound => 'No scales found yet.';

  @override
  String get availableScales => 'Available scales';

  @override
  String connectToDevice(String deviceName) {
    return 'Connect to $deviceName';
  }

  @override
  String get connecting => 'Connecting…';

  @override
  String get connectionFailed => 'Could not connect. Please try again.';

  @override
  String get bluetoothOff => 'Bluetooth is off. Turn it on to find your scale.';

  @override
  String get permissionNeeded =>
      'Bluetooth permission is needed to find your scale.';

  @override
  String get demoScaleName => 'Demo scale';

  @override
  String get homeTitle => 'Weight';

  @override
  String get currentWeightLabel => 'Current weight';

  @override
  String liveWeight(String weight) {
    return '$weight grams';
  }

  @override
  String get noTargetSet => 'No target set';

  @override
  String get tare => 'Tare';

  @override
  String get tareHint => 'Reset the scale to zero';

  @override
  String get setTarget => 'Set target';

  @override
  String get choosePreset => 'Choose preset';

  @override
  String get startLastTarget => 'Start last target';

  @override
  String get setTargetTitle => 'Set target weight';

  @override
  String decreaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Decrease by $count grams',
      one: 'Decrease by 1 gram',
    );
    return '$_temp0';
  }

  @override
  String increaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Increase by $count grams',
      one: 'Increase by 1 gram',
    );
    return '$_temp0';
  }

  @override
  String targetValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Target $count grams',
      one: 'Target 1 gram',
    );
    return '$_temp0';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get saveAsPreset => 'Save as preset';

  @override
  String get presetsTitle => 'Presets';

  @override
  String get addPreset => 'Add preset';

  @override
  String get newPreset => 'New preset';

  @override
  String get editPreset => 'Edit preset';

  @override
  String get presetNameField => 'Name';

  @override
  String get presetNameExample => 'e.g. Flour';

  @override
  String get presetWeightField => 'Target weight in grams';

  @override
  String get noPresets => 'No presets yet. Add one to get started.';

  @override
  String presetSummary(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grams',
      one: '1 gram',
    );
    return '$name, $_temp0';
  }

  @override
  String selectPreset(String name) {
    return 'Select $name';
  }

  @override
  String get deletePresetTitle => 'Delete preset?';

  @override
  String deletePresetMessage(String name) {
    return 'Delete the preset $name?';
  }

  @override
  String get presetSaved => 'Preset saved';

  @override
  String get presetNameRequired => 'Please enter a name.';

  @override
  String scalesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scales found',
      one: '1 scale found',
    );
    return '$_temp0';
  }

  @override
  String renamePresetNamed(String name) {
    return 'Rename $name';
  }

  @override
  String deletePresetNamed(String name) {
    return 'Delete $name';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get feedbackSectionTitle => 'Feedback';

  @override
  String get feedbackModeAudio => 'Sound';

  @override
  String get feedbackModeVibration => 'Vibration';

  @override
  String get feedbackModeAudioVibration => 'Sound and vibration';

  @override
  String get speechEnabled => 'Spoken announcements';

  @override
  String get speechEnabledDescription =>
      'Speak the grams remaining when you pause adding weight.';

  @override
  String get speechOutput => 'Speech output';

  @override
  String get speechOutputScreenReader => 'Screen reader voice';

  @override
  String get speechOutputAppVoice => 'App voice';

  @override
  String get speechOutputDescription =>
      'Screen reader keeps your own voice and speed, and reaches a braille display. The app\'s voice is used when no screen reader is running.';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get highContrast => 'High contrast';

  @override
  String get highContrastDescription =>
      'White on black in dark mode, black on yellow in light mode.';

  @override
  String get connectionSectionTitle => 'Connection';

  @override
  String get autoReconnect => 'Reconnect automatically';

  @override
  String get autoReconnectDescription =>
      'Reconnect to the last scale when the app opens.';

  @override
  String get demoMode => 'Demo mode';

  @override
  String get demoModeDescription =>
      'Use a simulated scale, no hardware required.';

  @override
  String announceRemaining(String value) {
    return '$value grams remaining';
  }

  @override
  String get announceTargetReached => 'Target reached';

  @override
  String announceOverTarget(String value) {
    return 'Over target by $value grams';
  }

  @override
  String get statusTargetReached => 'Target reached';

  @override
  String statusOverTarget(String value) {
    return 'Over target by $value grams';
  }

  @override
  String statusRemaining(String value) {
    return '$value grams remaining';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'NovaAccessScale reads your Bluetooth scale\'s weight aloud with sound, vibration, and speech, so you can weigh by ear. Announcements are spoken in grams when you pause adding weight.';

  @override
  String get contactSectionTitle => 'Contact';

  @override
  String get contactIntro =>
      'Questions, feedback, or ideas? We would love to hear from you.';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactEmailHint => 'Opens your email app';

  @override
  String get contactInstagramLabel => 'Instagram';

  @override
  String get contactInstagramHint => 'Opens Instagram';

  @override
  String get contactSupportLabel => 'Support the app';

  @override
  String get contactSupportHint => 'Opens Ko-fi in your browser';

  @override
  String get couldNotOpenLink => 'Could not open the link.';
}
