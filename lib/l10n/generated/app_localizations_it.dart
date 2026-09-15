// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'NovaAccessScale';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get close => 'Chiudi';

  @override
  String get gramsUnit => 'g';

  @override
  String get connectTitle => 'Connetti alla bilancia';

  @override
  String get connectInstruction => 'Connetti la bilancia per iniziare.';

  @override
  String get scanForScales => 'Cerca bilance';

  @override
  String get scanning => 'Ricerca in corso…';

  @override
  String get stopScanning => 'Interrompi la ricerca';

  @override
  String get noScalesFound => 'Nessuna bilancia trovata.';

  @override
  String get availableScales => 'Bilance disponibili';

  @override
  String connectToDevice(String deviceName) {
    return 'Connetti a $deviceName';
  }

  @override
  String get connecting => 'Connessione…';

  @override
  String get connectionFailed => 'Connessione non riuscita. Riprova.';

  @override
  String get bluetoothOff =>
      'Il Bluetooth è disattivato. Attivalo per trovare la bilancia.';

  @override
  String get permissionNeeded =>
      'È necessaria l’autorizzazione Bluetooth per trovare la bilancia.';

  @override
  String get demoScaleName => 'Bilancia dimostrativa';

  @override
  String get homeTitle => 'Peso';

  @override
  String get currentWeightLabel => 'Peso attuale';

  @override
  String liveWeight(String weight) {
    return '$weight grammi';
  }

  @override
  String get noTargetSet => 'Nessun obiettivo impostato';

  @override
  String get tare => 'Tara';

  @override
  String get tareHint => 'Azzera la bilancia';

  @override
  String get setTarget => 'Imposta obiettivo';

  @override
  String get choosePreset => 'Scegli preimpostazione';

  @override
  String get startLastTarget => 'Riprendi ultimo obiettivo';

  @override
  String get setTargetTitle => 'Imposta il peso obiettivo';

  @override
  String decreaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Diminuisci di $count grammi',
      one: 'Diminuisci di 1 grammo',
    );
    return '$_temp0';
  }

  @override
  String increaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aumenta di $count grammi',
      one: 'Aumenta di 1 grammo',
    );
    return '$_temp0';
  }

  @override
  String targetValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obiettivo $count grammi',
      one: 'Obiettivo 1 grammo',
    );
    return '$_temp0';
  }

  @override
  String get confirm => 'Conferma';

  @override
  String get saveAsPreset => 'Salva come preimpostazione';

  @override
  String get presetsTitle => 'Preimpostazioni';

  @override
  String get addPreset => 'Aggiungi preimpostazione';

  @override
  String get newPreset => 'Nuova preimpostazione';

  @override
  String get editPreset => 'Modifica preimpostazione';

  @override
  String get presetNameField => 'Nome';

  @override
  String get presetNameExample => 'es. Farina';

  @override
  String get presetWeightField => 'Peso obiettivo in grammi';

  @override
  String get noPresets =>
      'Nessuna preimpostazione. Aggiungine una per iniziare.';

  @override
  String presetSummary(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grammi',
      one: '1 grammo',
    );
    return '$name, $_temp0';
  }

  @override
  String selectPreset(String name) {
    return 'Seleziona $name';
  }

  @override
  String get deletePresetTitle => 'Eliminare la preimpostazione?';

  @override
  String deletePresetMessage(String name) {
    return 'Eliminare la preimpostazione $name?';
  }

  @override
  String get presetSaved => 'Preimpostazione salvata';

  @override
  String get presetNameRequired => 'Inserisci un nome.';

  @override
  String scalesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bilance trovate',
      one: '1 bilancia trovata',
    );
    return '$_temp0';
  }

  @override
  String renamePresetNamed(String name) {
    return 'Rinomina $name';
  }

  @override
  String deletePresetNamed(String name) {
    return 'Elimina $name';
  }

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get feedbackSectionTitle => 'Riscontro';

  @override
  String get feedbackModeAudio => 'Suono';

  @override
  String get feedbackModeVibration => 'Vibrazione';

  @override
  String get feedbackModeAudioVibration => 'Suono e vibrazione';

  @override
  String get speechEnabled => 'Annunci vocali';

  @override
  String get speechEnabledDescription =>
      'Annuncia i grammi rimanenti quando ti fermi.';

  @override
  String get speechOutput => 'Uscita vocale';

  @override
  String get speechOutputScreenReader => 'Voce del lettore di schermo';

  @override
  String get speechOutputAppVoice => 'Voce dell’app';

  @override
  String get speechOutputDescription =>
      'Il lettore di schermo mantiene la tua voce e la tua velocità e raggiunge un display braille. La voce dell’app viene usata quando nessun lettore di schermo è attivo.';

  @override
  String get appearanceSectionTitle => 'Aspetto';

  @override
  String get highContrast => 'Alto contrasto';

  @override
  String get highContrastDescription =>
      'Bianco su nero in modalità scura, nero su giallo in modalità chiara.';

  @override
  String get connectionSectionTitle => 'Connessione';

  @override
  String get autoReconnect => 'Riconnetti automaticamente';

  @override
  String get autoReconnectDescription =>
      'Riconnetti all’ultima bilancia all’avvio dell’app.';

  @override
  String get demoMode => 'Modalità demo';

  @override
  String get demoModeDescription =>
      'Usa una bilancia simulata, senza hardware.';

  @override
  String announceRemaining(String value) {
    return '$value grammi rimanenti';
  }

  @override
  String get announceTargetReached => 'Obiettivo raggiunto';

  @override
  String announceOverTarget(String value) {
    return '$value grammi oltre l’obiettivo';
  }

  @override
  String get statusTargetReached => 'Obiettivo raggiunto';

  @override
  String statusOverTarget(String value) {
    return '$value grammi oltre l’obiettivo';
  }

  @override
  String statusRemaining(String value) {
    return '$value grammi rimanenti';
  }

  @override
  String get aboutTitle => 'Informazioni';

  @override
  String get aboutBody =>
      'NovaAccessScale legge ad alta voce il peso della tua bilancia Bluetooth con suono, vibrazione e voce, così puoi pesare a orecchio. Gli annunci sono in grammi quando smetti di aggiungere peso.';

  @override
  String get contactSectionTitle => 'Contatti';

  @override
  String get contactIntro =>
      'Domande, feedback o idee? Ci farebbe piacere sentirti.';

  @override
  String get contactEmailLabel => 'E-mail';

  @override
  String get contactEmailHint => 'Apre la tua app e-mail';

  @override
  String get contactInstagramLabel => 'Instagram';

  @override
  String get contactInstagramHint => 'Apre Instagram';

  @override
  String get contactSupportLabel => 'Sostieni l’app';

  @override
  String get contactSupportHint => 'Apre Ko-fi nel browser';

  @override
  String get couldNotOpenLink => 'Impossibile aprire il link.';
}
