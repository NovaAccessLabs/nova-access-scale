import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// Application name.
  ///
  /// In en, this message translates to:
  /// **'NovaAccessScale'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Short unit suffix for grams shown next to a number.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get gramsUnit;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to scale'**
  String get connectTitle;

  /// No description provided for @connectInstruction.
  ///
  /// In en, this message translates to:
  /// **'Connect your scale to begin.'**
  String get connectInstruction;

  /// No description provided for @scanForScales.
  ///
  /// In en, this message translates to:
  /// **'Scan for scales'**
  String get scanForScales;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @stopScanning.
  ///
  /// In en, this message translates to:
  /// **'Stop scanning'**
  String get stopScanning;

  /// No description provided for @noScalesFound.
  ///
  /// In en, this message translates to:
  /// **'No scales found yet.'**
  String get noScalesFound;

  /// Semantic heading for the list of discovered scales.
  ///
  /// In en, this message translates to:
  /// **'Available scales'**
  String get availableScales;

  /// Button label to connect to a specific discovered scale.
  ///
  /// In en, this message translates to:
  /// **'Connect to {deviceName}'**
  String connectToDevice(String deviceName);

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Please try again.'**
  String get connectionFailed;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on to find your scale.'**
  String get bluetoothOff;

  /// No description provided for @permissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is needed to find your scale.'**
  String get permissionNeeded;

  /// Display name for the simulated scale used in demo mode.
  ///
  /// In en, this message translates to:
  /// **'Demo scale'**
  String get demoScaleName;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get homeTitle;

  /// No description provided for @currentWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get currentWeightLabel;

  /// Spoken/semantic form of the live weight reading.
  ///
  /// In en, this message translates to:
  /// **'{weight} grams'**
  String liveWeight(String weight);

  /// No description provided for @noTargetSet.
  ///
  /// In en, this message translates to:
  /// **'No target set'**
  String get noTargetSet;

  /// No description provided for @tare.
  ///
  /// In en, this message translates to:
  /// **'Tare'**
  String get tare;

  /// No description provided for @tareHint.
  ///
  /// In en, this message translates to:
  /// **'Reset the scale to zero'**
  String get tareHint;

  /// No description provided for @setTarget.
  ///
  /// In en, this message translates to:
  /// **'Set target'**
  String get setTarget;

  /// No description provided for @choosePreset.
  ///
  /// In en, this message translates to:
  /// **'Choose preset'**
  String get choosePreset;

  /// No description provided for @startLastTarget.
  ///
  /// In en, this message translates to:
  /// **'Start last target'**
  String get startLastTarget;

  /// No description provided for @setTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set target weight'**
  String get setTargetTitle;

  /// Accessibility label for the minus stepper buttons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Decrease by 1 gram} other{Decrease by {count} grams}}'**
  String decreaseByGrams(int count);

  /// Accessibility label for the plus stepper buttons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Increase by 1 gram} other{Increase by {count} grams}}'**
  String increaseByGrams(int count);

  /// Semantic label announcing the current target value.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Target 1 gram} other{Target {count} grams}}'**
  String targetValue(int count);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @saveAsPreset.
  ///
  /// In en, this message translates to:
  /// **'Save as preset'**
  String get saveAsPreset;

  /// No description provided for @presetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presetsTitle;

  /// No description provided for @addPreset.
  ///
  /// In en, this message translates to:
  /// **'Add preset'**
  String get addPreset;

  /// No description provided for @newPreset.
  ///
  /// In en, this message translates to:
  /// **'New preset'**
  String get newPreset;

  /// No description provided for @editPreset.
  ///
  /// In en, this message translates to:
  /// **'Edit preset'**
  String get editPreset;

  /// No description provided for @presetNameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get presetNameField;

  /// No description provided for @presetNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flour'**
  String get presetNameExample;

  /// No description provided for @presetWeightField.
  ///
  /// In en, this message translates to:
  /// **'Target weight in grams'**
  String get presetWeightField;

  /// No description provided for @noPresets.
  ///
  /// In en, this message translates to:
  /// **'No presets yet. Add one to get started.'**
  String get noPresets;

  /// Semantic label for a preset list item.
  ///
  /// In en, this message translates to:
  /// **'{name}, {count, plural, =1{1 gram} other{{count} grams}}'**
  String presetSummary(String name, int count);

  /// Accessibility label to choose a preset.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String selectPreset(String name);

  /// No description provided for @deletePresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete preset?'**
  String get deletePresetTitle;

  /// No description provided for @deletePresetMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the preset {name}?'**
  String deletePresetMessage(String name);

  /// No description provided for @presetSaved.
  ///
  /// In en, this message translates to:
  /// **'Preset saved'**
  String get presetSaved;

  /// No description provided for @presetNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get presetNameRequired;

  /// Screen-reader announcement when a scan turns up scales; the list appearing is otherwise silent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scale found} other{{count} scales found}}'**
  String scalesFound(int count);

  /// Accessible label for the rename button on a preset row. Names the preset so rows are distinguishable.
  ///
  /// In en, this message translates to:
  /// **'Rename {name}'**
  String renamePresetNamed(String name);

  /// No description provided for @deletePresetNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deletePresetNamed(String name);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @feedbackSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackSectionTitle;

  /// No description provided for @feedbackModeAudio.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get feedbackModeAudio;

  /// No description provided for @feedbackModeVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get feedbackModeVibration;

  /// No description provided for @feedbackModeAudioVibration.
  ///
  /// In en, this message translates to:
  /// **'Sound and vibration'**
  String get feedbackModeAudioVibration;

  /// No description provided for @speechEnabled.
  ///
  /// In en, this message translates to:
  /// **'Spoken announcements'**
  String get speechEnabled;

  /// No description provided for @speechEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Speak the grams remaining when you pause adding weight.'**
  String get speechEnabledDescription;

  /// Setting group choosing which voice speaks announcements: the user's screen reader or the app's own voice. Only shown while a screen reader is active.
  ///
  /// In en, this message translates to:
  /// **'Speech output'**
  String get speechOutput;

  /// Speech output option: announce through the screen reader (TalkBack) when one is running, otherwise use the app's own voice.
  ///
  /// In en, this message translates to:
  /// **'Screen reader voice'**
  String get speechOutputScreenReader;

  /// No description provided for @speechOutputAppVoice.
  ///
  /// In en, this message translates to:
  /// **'App voice'**
  String get speechOutputAppVoice;

  /// No description provided for @speechOutputDescription.
  ///
  /// In en, this message translates to:
  /// **'Screen reader keeps your own voice and speed, and reaches a braille display. The app\'s voice is used when no screen reader is running.'**
  String get speechOutputDescription;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'White on black in dark mode, black on yellow in light mode.'**
  String get highContrastDescription;

  /// No description provided for @connectionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionSectionTitle;

  /// No description provided for @autoReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect automatically'**
  String get autoReconnect;

  /// No description provided for @autoReconnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to the last scale when the app opens.'**
  String get autoReconnectDescription;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoMode;

  /// No description provided for @demoModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Use a simulated scale, no hardware required.'**
  String get demoModeDescription;

  /// Spoken announcement of grams left to reach the target (0.1 g).
  ///
  /// In en, this message translates to:
  /// **'{value} grams remaining'**
  String announceRemaining(String value);

  /// No description provided for @announceTargetReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get announceTargetReached;

  /// Spoken announcement when above the target (0.1 g).
  ///
  /// In en, this message translates to:
  /// **'Over target by {value} grams'**
  String announceOverTarget(String value);

  /// No description provided for @statusTargetReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get statusTargetReached;

  /// No description provided for @statusOverTarget.
  ///
  /// In en, this message translates to:
  /// **'Over target by {value} grams'**
  String statusOverTarget(String value);

  /// No description provided for @statusRemaining.
  ///
  /// In en, this message translates to:
  /// **'{value} grams remaining'**
  String statusRemaining(String value);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// Short description of the app shown in a note box on the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'NovaAccessScale reads your Bluetooth scale\'s weight aloud with sound, vibration, and speech, so you can weigh by ear. Announcements are spoken in grams when you pause adding weight.'**
  String get aboutBody;

  /// No description provided for @contactSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactSectionTitle;

  /// Intro line above the contact links.
  ///
  /// In en, this message translates to:
  /// **'Questions, feedback, or ideas? We would love to hear from you.'**
  String get contactIntro;

  /// Action label for the e-mail contact link (the address is shown as the subtitle).
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// Screen-reader hint describing what the email link opens.
  ///
  /// In en, this message translates to:
  /// **'Opens your email app'**
  String get contactEmailHint;

  /// Action label for the Instagram link (the handle is shown as the subtitle).
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get contactInstagramLabel;

  /// Screen-reader hint describing what the Instagram link opens.
  ///
  /// In en, this message translates to:
  /// **'Opens Instagram'**
  String get contactInstagramHint;

  /// Action label for the Ko-fi support link (the handle is shown as the subtitle).
  ///
  /// In en, this message translates to:
  /// **'Support the app'**
  String get contactSupportLabel;

  /// Screen-reader hint describing what the support link opens.
  ///
  /// In en, this message translates to:
  /// **'Opens Ko-fi in your browser'**
  String get contactSupportHint;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get couldNotOpenLink;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
