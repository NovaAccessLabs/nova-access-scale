// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'NovaAccessScale';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get close => 'Cerrar';

  @override
  String get gramsUnit => 'g';

  @override
  String get connectTitle => 'Conectar con la báscula';

  @override
  String get connectInstruction => 'Conecta la báscula para empezar.';

  @override
  String get scanForScales => 'Buscar básculas';

  @override
  String get scanning => 'Buscando…';

  @override
  String get stopScanning => 'Detener la búsqueda';

  @override
  String get noScalesFound => 'No se han encontrado básculas.';

  @override
  String get availableScales => 'Básculas disponibles';

  @override
  String connectToDevice(String deviceName) {
    return 'Conectar con $deviceName';
  }

  @override
  String get connecting => 'Conectando…';

  @override
  String get connectionFailed => 'No se pudo conectar. Inténtalo de nuevo.';

  @override
  String get bluetoothOff =>
      'El Bluetooth está desactivado. Actívalo para encontrar la báscula.';

  @override
  String get permissionNeeded =>
      'Se necesita el permiso de Bluetooth para encontrar la báscula.';

  @override
  String get demoScaleName => 'Báscula de demostración';

  @override
  String get homeTitle => 'Peso';

  @override
  String get currentWeightLabel => 'Peso actual';

  @override
  String liveWeight(String weight) {
    return '$weight gramos';
  }

  @override
  String get noTargetSet => 'Sin objetivo definido';

  @override
  String get tare => 'Tara';

  @override
  String get tareHint => 'Poner la báscula a cero';

  @override
  String get setTarget => 'Definir objetivo';

  @override
  String get choosePreset => 'Elegir preajuste';

  @override
  String get startLastTarget => 'Retomar el último objetivo';

  @override
  String get setTargetTitle => 'Definir el peso objetivo';

  @override
  String decreaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reducir $count gramos',
      one: 'Reducir 1 gramo',
    );
    return '$_temp0';
  }

  @override
  String increaseByGrams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aumentar $count gramos',
      one: 'Aumentar 1 gramo',
    );
    return '$_temp0';
  }

  @override
  String targetValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Objetivo $count gramos',
      one: 'Objetivo 1 gramo',
    );
    return '$_temp0';
  }

  @override
  String get confirm => 'Confirmar';

  @override
  String get saveAsPreset => 'Guardar como preajuste';

  @override
  String get presetsTitle => 'Preajustes';

  @override
  String get addPreset => 'Añadir preajuste';

  @override
  String get newPreset => 'Nuevo preajuste';

  @override
  String get editPreset => 'Editar preajuste';

  @override
  String get presetNameField => 'Nombre';

  @override
  String get presetNameExample => 'p. ej. Harina';

  @override
  String get presetWeightField => 'Peso objetivo en gramos';

  @override
  String get noPresets => 'No hay preajustes. Añade uno para empezar.';

  @override
  String presetSummary(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gramos',
      one: '1 gramo',
    );
    return '$name, $_temp0';
  }

  @override
  String selectPreset(String name) {
    return 'Seleccionar $name';
  }

  @override
  String get deletePresetTitle => '¿Eliminar el preajuste?';

  @override
  String deletePresetMessage(String name) {
    return '¿Eliminar el preajuste $name?';
  }

  @override
  String get presetSaved => 'Preajuste guardado';

  @override
  String get presetNameRequired => 'Introduce un nombre.';

  @override
  String scalesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count básculas encontradas',
      one: '1 báscula encontrada',
    );
    return '$_temp0';
  }

  @override
  String renamePresetNamed(String name) {
    return 'Cambiar el nombre de $name';
  }

  @override
  String deletePresetNamed(String name) {
    return 'Eliminar $name';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get feedbackSectionTitle => 'Respuesta';

  @override
  String get feedbackModeAudio => 'Sonido';

  @override
  String get feedbackModeVibration => 'Vibración';

  @override
  String get feedbackModeAudioVibration => 'Sonido y vibración';

  @override
  String get speechEnabled => 'Anuncios hablados';

  @override
  String get speechEnabledDescription =>
      'Anunciar los gramos restantes cuando dejas de añadir peso.';

  @override
  String get speechOutput => 'Salida de voz';

  @override
  String get speechOutputScreenReader => 'Voz del lector de pantalla';

  @override
  String get speechOutputAppVoice => 'Voz de la aplicación';

  @override
  String get speechOutputDescription =>
      'El lector de pantalla mantiene tu voz y tu velocidad, y llega a una línea braille. La voz de la aplicación se usa cuando no hay ningún lector de pantalla activo.';

  @override
  String get appearanceSectionTitle => 'Apariencia';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get highContrastDescription =>
      'Blanco sobre negro en modo oscuro, negro sobre amarillo en modo claro.';

  @override
  String get connectionSectionTitle => 'Conexión';

  @override
  String get autoReconnect => 'Reconectar automáticamente';

  @override
  String get autoReconnectDescription =>
      'Reconectar con la última báscula al abrir la aplicación.';

  @override
  String get demoMode => 'Modo demostración';

  @override
  String get demoModeDescription => 'Usa una báscula simulada, sin hardware.';

  @override
  String announceRemaining(String value) {
    return 'Quedan $value gramos';
  }

  @override
  String get announceTargetReached => 'Objetivo alcanzado';

  @override
  String announceOverTarget(String value) {
    return '$value gramos de más';
  }

  @override
  String get statusTargetReached => 'Objetivo alcanzado';

  @override
  String statusOverTarget(String value) {
    return '$value gramos de más';
  }

  @override
  String statusRemaining(String value) {
    return 'Quedan $value gramos';
  }

  @override
  String get aboutTitle => 'Información';

  @override
  String get aboutBody =>
      'NovaAccessScale lee en voz alta el peso de tu báscula Bluetooth con sonido, vibración y voz, para que puedas pesar de oído. Los anuncios se dan en gramos cuando dejas de añadir peso.';

  @override
  String get contactSectionTitle => 'Contacto';

  @override
  String get contactIntro =>
      '¿Preguntas, comentarios o ideas? Nos encantará saber de ti.';

  @override
  String get contactEmailLabel => 'Correo electrónico';

  @override
  String get contactEmailHint => 'Abre tu aplicación de correo';

  @override
  String get contactInstagramLabel => 'Instagram';

  @override
  String get contactInstagramHint => 'Abre Instagram';

  @override
  String get contactSupportLabel => 'Apoya la aplicación';

  @override
  String get contactSupportHint => 'Abre Ko-fi en tu navegador';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace.';
}
