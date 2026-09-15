// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'NovaAccessScale';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get close => 'Fermer';

  @override
  String get gramsUnit => 'g';

  @override
  String get connectTitle => 'Connexion à la balance';

  @override
  String get connectInstruction => 'Connectez votre balance pour commencer.';

  @override
  String get scanForScales => 'Rechercher des balances';

  @override
  String get scanning => 'Recherche en cours…';

  @override
  String get stopScanning => 'Arrêter la recherche';

  @override
  String get noScalesFound => 'Aucune balance trouvée pour le moment.';

  @override
  String get availableScales => 'Balances disponibles';

  @override
  String connectToDevice(String deviceName) {
    return 'Se connecter à $deviceName';
  }

  @override
  String get connecting => 'Connexion…';

  @override
  String get connectionFailed => 'Connexion impossible. Veuillez réessayer.';

  @override
  String get bluetoothOff =>
      'Le Bluetooth est désactivé. Activez-le pour trouver votre balance.';

  @override
  String get permissionNeeded =>
      'L’autorisation Bluetooth est nécessaire pour trouver votre balance.';

  @override
  String get demoScaleName => 'Balance de démonstration';

  @override
  String get homeTitle => 'Poids';

  @override
  String get currentWeightLabel => 'Poids actuel';

  @override
  String liveWeight(String weight) {
    return '$weight grammes';
  }

  @override
  String get noTargetSet => 'Aucune cible définie';

  @override
  String get tare => 'Tare';

  @override
  String get tareHint => 'Remettre la balance à zéro';

  @override
  String get setTarget => 'Définir la cible';

  @override
  String get choosePreset => 'Choisir un préréglage';

  @override
  String get startLastTarget => 'Reprendre la dernière cible';

  @override
  String get setTargetTitle => 'Définir le poids cible';

  @override
  String decreaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Diminuer de $count grammes',
      one: 'Diminuer de 1 gramme',
    );
    return '$_temp0';
  }

  @override
  String increaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Augmenter de $count grammes',
      one: 'Augmenter de 1 gramme',
    );
    return '$_temp0';
  }

  @override
  String targetValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cible $count grammes',
      one: 'Cible 1 gramme',
    );
    return '$_temp0';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get saveAsPreset => 'Enregistrer comme préréglage';

  @override
  String get presetsTitle => 'Préréglages';

  @override
  String get addPreset => 'Ajouter un préréglage';

  @override
  String get newPreset => 'Nouveau préréglage';

  @override
  String get editPreset => 'Modifier le préréglage';

  @override
  String get presetNameField => 'Nom';

  @override
  String get presetNameExample => 'ex. Farine';

  @override
  String get presetWeightField => 'Poids cible en grammes';

  @override
  String get noPresets => 'Aucun préréglage. Ajoutez-en un pour commencer.';

  @override
  String presetSummary(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grammes',
      one: '1 gramme',
    );
    return '$name, $_temp0';
  }

  @override
  String selectPreset(String name) {
    return 'Sélectionner $name';
  }

  @override
  String get deletePresetTitle => 'Supprimer le préréglage ?';

  @override
  String deletePresetMessage(String name) {
    return 'Supprimer le préréglage $name ?';
  }

  @override
  String get presetSaved => 'Préréglage enregistré';

  @override
  String get presetNameRequired => 'Veuillez saisir un nom.';

  @override
  String scalesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count balances trouvées',
      one: '1 balance trouvée',
    );
    return '$_temp0';
  }

  @override
  String renamePresetNamed(String name) {
    return 'Renommer $name';
  }

  @override
  String deletePresetNamed(String name) {
    return 'Supprimer $name';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get feedbackSectionTitle => 'Retour d’information';

  @override
  String get feedbackModeAudio => 'Son';

  @override
  String get feedbackModeVibration => 'Vibration';

  @override
  String get feedbackModeAudioVibration => 'Son et vibration';

  @override
  String get speechEnabled => 'Annonces vocales';

  @override
  String get speechEnabledDescription =>
      'Annoncer les grammes restants lorsque vous faites une pause.';

  @override
  String get speechOutput => 'Sortie vocale';

  @override
  String get speechOutputScreenReader => 'Voix du lecteur d’écran';

  @override
  String get speechOutputAppVoice => 'Voix de l’application';

  @override
  String get speechOutputDescription =>
      'Le lecteur d’écran conserve votre voix et votre vitesse, et alimente un afficheur braille. La voix de l’application est utilisée si aucun lecteur d’écran n’est actif.';

  @override
  String get appearanceSectionTitle => 'Apparence';

  @override
  String get highContrast => 'Contraste élevé';

  @override
  String get highContrastDescription =>
      'Blanc sur noir en mode sombre, noir sur jaune en mode clair.';

  @override
  String get connectionSectionTitle => 'Connexion';

  @override
  String get autoReconnect => 'Reconnexion automatique';

  @override
  String get autoReconnectDescription =>
      'Se reconnecter à la dernière balance à l’ouverture de l’application.';

  @override
  String get demoMode => 'Mode démonstration';

  @override
  String get demoModeDescription =>
      'Utiliser une balance simulée, sans matériel.';

  @override
  String announceRemaining(String value) {
    return '$value grammes restants';
  }

  @override
  String get announceTargetReached => 'Cible atteinte';

  @override
  String announceOverTarget(String value) {
    return 'Dépassement de $value grammes';
  }

  @override
  String get statusTargetReached => 'Cible atteinte';

  @override
  String statusOverTarget(String value) {
    return 'Dépassement de $value grammes';
  }

  @override
  String statusRemaining(String value) {
    return '$value grammes restants';
  }

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutBody =>
      'NovaAccessScale lit à voix haute le poids de votre balance Bluetooth avec du son, des vibrations et la parole, pour peser à l’oreille. Les annonces sont dites en grammes lorsque vous cessez d’ajouter du poids.';

  @override
  String get contactSectionTitle => 'Contact';

  @override
  String get contactIntro =>
      'Des questions, des retours ou des idées ? Nous serions ravis de vous lire.';

  @override
  String get contactEmailLabel => 'E-mail';

  @override
  String get contactEmailHint => 'Ouvre votre application e-mail';

  @override
  String get contactInstagramLabel => 'Instagram';

  @override
  String get contactInstagramHint => 'Ouvre Instagram';

  @override
  String get contactSupportLabel => 'Soutenir l’application';

  @override
  String get contactSupportHint => 'Ouvre Ko-fi dans votre navigateur';

  @override
  String get couldNotOpenLink => 'Impossible d’ouvrir le lien.';
}
