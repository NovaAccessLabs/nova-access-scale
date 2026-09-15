// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'NovaAccessScale';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get close => 'Schließen';

  @override
  String get gramsUnit => 'g';

  @override
  String get connectTitle => 'Mit Waage verbinden';

  @override
  String get connectInstruction => 'Verbinden Sie Ihre Waage, um zu beginnen.';

  @override
  String get scanForScales => 'Nach Waagen suchen';

  @override
  String get scanning => 'Suche läuft…';

  @override
  String get stopScanning => 'Suche beenden';

  @override
  String get noScalesFound => 'Noch keine Waagen gefunden.';

  @override
  String get availableScales => 'Verfügbare Waagen';

  @override
  String connectToDevice(String deviceName) {
    return 'Mit $deviceName verbinden';
  }

  @override
  String get connecting => 'Verbinden…';

  @override
  String get connectionFailed =>
      'Verbindung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get bluetoothOff =>
      'Bluetooth ist aus. Schalten Sie es ein, um Ihre Waage zu finden.';

  @override
  String get permissionNeeded =>
      'Für die Suche nach Ihrer Waage wird die Bluetooth-Berechtigung benötigt.';

  @override
  String get demoScaleName => 'Demo-Waage';

  @override
  String get homeTitle => 'Gewicht';

  @override
  String get currentWeightLabel => 'Aktuelles Gewicht';

  @override
  String liveWeight(String weight) {
    return '$weight Gramm';
  }

  @override
  String get noTargetSet => 'Kein Ziel festgelegt';

  @override
  String get tare => 'Tara';

  @override
  String get tareHint => 'Die Waage auf null zurücksetzen';

  @override
  String get setTarget => 'Ziel festlegen';

  @override
  String get choosePreset => 'Voreinstellung wählen';

  @override
  String get startLastTarget => 'Letztes Ziel starten';

  @override
  String get setTargetTitle => 'Zielgewicht festlegen';

  @override
  String decreaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Um $count Gramm verringern',
      one: 'Um 1 Gramm verringern',
    );
    return '$_temp0';
  }

  @override
  String increaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Um $count Gramm erhöhen',
      one: 'Um 1 Gramm erhöhen',
    );
    return '$_temp0';
  }

  @override
  String targetValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ziel $count Gramm',
      one: 'Ziel 1 Gramm',
    );
    return '$_temp0';
  }

  @override
  String get confirm => 'Bestätigen';

  @override
  String get saveAsPreset => 'Als Voreinstellung speichern';

  @override
  String get presetsTitle => 'Voreinstellungen';

  @override
  String get addPreset => 'Voreinstellung hinzufügen';

  @override
  String get newPreset => 'Neue Voreinstellung';

  @override
  String get editPreset => 'Voreinstellung bearbeiten';

  @override
  String get presetNameField => 'Name';

  @override
  String get presetNameExample => 'z. B. Mehl';

  @override
  String get presetWeightField => 'Zielgewicht in Gramm';

  @override
  String get noPresets =>
      'Noch keine Voreinstellungen. Fügen Sie eine hinzu, um zu beginnen.';

  @override
  String presetSummary(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gramm',
      one: '1 Gramm',
    );
    return '$name, $_temp0';
  }

  @override
  String selectPreset(String name) {
    return '$name auswählen';
  }

  @override
  String get deletePresetTitle => 'Voreinstellung löschen?';

  @override
  String deletePresetMessage(String name) {
    return 'Die Voreinstellung $name löschen?';
  }

  @override
  String get presetSaved => 'Voreinstellung gespeichert';

  @override
  String get presetNameRequired => 'Bitte geben Sie einen Namen ein.';

  @override
  String scalesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Waagen gefunden',
      one: '1 Waage gefunden',
    );
    return '$_temp0';
  }

  @override
  String renamePresetNamed(String name) {
    return '$name umbenennen';
  }

  @override
  String deletePresetNamed(String name) {
    return '$name löschen';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get feedbackSectionTitle => 'Rückmeldung';

  @override
  String get feedbackModeAudio => 'Ton';

  @override
  String get feedbackModeVibration => 'Vibration';

  @override
  String get feedbackModeAudioVibration => 'Ton und Vibration';

  @override
  String get speechEnabled => 'Sprachansagen';

  @override
  String get speechEnabledDescription =>
      'Die verbleibenden Gramm ansagen, wenn Sie pausieren.';

  @override
  String get speechOutput => 'Sprachausgabe';

  @override
  String get speechOutputScreenReader => 'Stimme des Bildschirmlesers';

  @override
  String get speechOutputAppVoice => 'App-Stimme';

  @override
  String get speechOutputDescription =>
      'Der Bildschirmleser behält Ihre eigene Stimme und Geschwindigkeit und erreicht eine Braillezeile. Die App-Stimme wird verwendet, wenn kein Bildschirmleser aktiv ist.';

  @override
  String get appearanceSectionTitle => 'Darstellung';

  @override
  String get highContrast => 'Hoher Kontrast';

  @override
  String get highContrastDescription =>
      'Weiß auf Schwarz im dunklen Modus, Schwarz auf Gelb im hellen Modus.';

  @override
  String get connectionSectionTitle => 'Verbindung';

  @override
  String get autoReconnect => 'Automatisch neu verbinden';

  @override
  String get autoReconnectDescription =>
      'Beim Öffnen der App erneut mit der letzten Waage verbinden.';

  @override
  String get demoMode => 'Demomodus';

  @override
  String get demoModeDescription =>
      'Eine simulierte Waage ohne Hardware verwenden.';

  @override
  String announceRemaining(String value) {
    return 'Noch $value Gramm';
  }

  @override
  String get announceTargetReached => 'Ziel erreicht';

  @override
  String announceOverTarget(String value) {
    return '$value Gramm über dem Ziel';
  }

  @override
  String get statusTargetReached => 'Ziel erreicht';

  @override
  String statusOverTarget(String value) {
    return '$value Gramm über dem Ziel';
  }

  @override
  String statusRemaining(String value) {
    return 'Noch $value Gramm';
  }

  @override
  String get aboutTitle => 'Über';

  @override
  String get aboutBody =>
      'NovaAccessScale liest das Gewicht Ihrer Bluetooth-Waage mit Ton, Vibration und Sprache vor, damit Sie nach Gehör wiegen können. Ansagen erfolgen in Gramm, wenn Sie mit dem Hinzufügen von Gewicht pausieren.';

  @override
  String get contactSectionTitle => 'Kontakt';

  @override
  String get contactIntro =>
      'Fragen, Feedback oder Ideen? Wir freuen uns, von Ihnen zu hören.';

  @override
  String get contactEmailLabel => 'E-Mail';

  @override
  String get contactEmailHint => 'Öffnet Ihre E-Mail-App';

  @override
  String get contactInstagramLabel => 'Instagram';

  @override
  String get contactInstagramHint => 'Öffnet Instagram';

  @override
  String get contactSupportLabel => 'App unterstützen';

  @override
  String get contactSupportHint => 'Öffnet Ko-fi in Ihrem Browser';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden.';
}
