# Developing NovaAccessScale

Technical reference for building, testing, and extending the app. For what the
app does and why, see [`README.md`](README.md).

The design rationale is kept in the code itself: the architecture notes below,
plus doc comments on the pieces that carry non-obvious constraints
(`lib/feedback/speech_router.dart` for speech routing,
`lib/theme/app_colors.dart` for the color tokens,
`lib/scale/scale_protocol.dart` for the scale seam).

## Status

- **Android**: validated on-device — Pixel 4a 5G (real MyScale connection,
  current build), plus earlier validation on Nexus 5X / API 27 and Redmi 9 /
  API 33.

## Architecture

UI never talks to Bluetooth or device-specific framing directly. Everything goes
through small, testable layers:

```
Screens (Flutter widgets)
  └─ Controllers (ChangeNotifier): ScaleController, SettingsController, PresetController
       ├─ FeedbackCoordinator ── TargetFeedbackEngine + StabilityDetector (pure Dart)
       │     └─ PulseFeedbackOutput / SpeechOutput  (audio, vibration, TTS)
       ├─ ScaleProtocol  ◄── the single seam for scale support
       │     ├─ MockScaleProtocol      (demo / tests)
       │     └─ MyScaleScaleProtocol   (real BLE, see README "Supported scales")
       ├─ ScaleProtocolRegistry / ScaleBleService  (scan + match)
       └─ Repositories ── SharedPreferences
```

- **State management**: `ChangeNotifier` only (no external package); controllers
  are provided via the dependency-free `AppScope` `InheritedWidget`.
- **Feedback decisions are pure Dart** (`TargetFeedbackEngine`,
  `StabilityDetector`) and fully unit-tested. The output channels sit behind
  interfaces (`PulseFeedbackOutput`, `SpeechOutput`) so the coordinator is
  testable with fakes and backends are swappable.
- **Theming**: semantic tokens in a typed `BrandColors` `ThemeExtension`;
  widgets read `context.colors` — no raw hex. Light/dark follow the OS
  automatically (no manual override); a single **High contrast** toggle in
  Settings switches to white-on-black (dark) or black-on-yellow (light) —
  comfort yellow `#FFD400`. Text uses
  bundled Manrope + Atkinson Hyperlegible, and respects the device's text-size
  setting (no in-app text-size picker). Page transitions skip animation when
  the OS "reduce motion" preference is on.
- **Speech routing**: `SpeechOutputMode` (screen reader / app voice) is only
  offered as a live choice in Settings while a screen reader is detected
  (`MediaQuery.accessibleNavigation`) — with none running every mode already
  resolves to the app's own voice, so the picker is hidden rather than
  offering a non-choice. See `lib/feedback/speech_router.dart`.
- **Settings UI**: option groups are large pill toggles (`LabeledOptionPicker`),
  not radios or sliders — one selected pill, conveyed by fill + check icon + the
  `selected` semantic flag. About and Contact are inline on the Settings screen.
- **Localization**: `flutter gen-l10n` from `lib/l10n/*.arb`; device locale is
  matched automatically with English fallback — no in-app language picker.

### Feedback behaviour

Tuned for flickery scales, so a noisy reading never triggers premature feedback:

- **Approaching** — a soft "ding" earcon (synthesised in-memory by
  `ToneSynthesizer`, no audio assets) repeats on a cadence that shortens as the
  weight nears the target.
- **Reached / over** — reported only once the weight *stays* in the target band
  (±0.05 g) or past it for a confirm delay (`reachedConfirmDelay` /
  `overConfirmDelay`). A brief flicker through the target, or a momentary
  overshoot, is ignored. The debounce happens at the source, so the same state
  drives the cue, the spoken announcement, **and** the on-screen status — the
  screen reader never jumps ahead of the audio.
- **Grams remaining** — spoken only when the user pauses (weight stable within
  ±0.5 g for 1 s, via `StabilityDetector`), then after a settle delay
  (`announceSettleDelay`) using the latest reading, so the figure reflects a
  settled scale rather than a transient.

The three delays are fields on `FeedbackCoordinator` (default 1 s each; set to
`Duration.zero` to react immediately).

Selecting a feedback mode in Settings confirms on the channels it enables — a
haptic buzz for vibration modes, a short earcon for sound modes — so the choice
is felt/heard without starting a weigh.

## Adding a new scale

The `ScaleProtocol` interface is the only seam you touch — no UI or controller
changes are needed.

1. **Implement `ScaleProtocol`** in `lib/scale/your_scale_protocol.dart`:
   - `isSupported(advertisedName)` — recognize the device from its BLE name.
   - `connect` / `disconnect` / `tare`.
   - `weightStream` (grams) and `statusStream`.
   Use `MyScaleScaleProtocol` as a reference (BLE) and keep the pure decode
   logic (frame parsing, checksums) as static methods so they can be unit-tested
   without hardware.
2. **Register it** in [`lib/scale/scale_registry.dart`](lib/scale/scale_registry.dart):
   ```dart
   ScaleProtocolDescriptor(
     protocolId: 'your_scale',
     matches: YourScaleProtocol.matchesAdvertisedName,
     create: YourScaleProtocol.new,
   ),
   ```
3. **Unit-test the pure parts** (frame decode, name matching). The BLE I/O path
   is verified manually on a device.

That's it — scanning, connection, feedback, presets, and all screens work with
the new scale automatically.

## Project layout

```
lib/
  app.dart, main.dart, app_scope.dart   App entry, root gate, DI
  models/         Preset, AppSettings, enums (FeedbackMode, SpeechOutputMode)
  repositories/   SharedPreferences-backed persistence
  scale/          ScaleProtocol, registry, BLE service, Mock + MyScale protocol
  feedback/       Engine, stability detector, coordinator, audio/vibration/speech
  controllers/    ScaleController, SettingsController, PresetController
  theme/          Color tokens, typography, ThemeData builder
  widgets/        WeightStepper (no-slider stepper), LabeledOptionPicker (pills)
  screens/        Connection, Home, Target selector, Presets, Settings
  l10n/           ARB sources + generated delegates
test/             Unit + widget tests
screenshots/       Screenshots used by the README
```

## Building and running

Toolchain: Flutter 3.44.1 (Dart 3.12).

```bash
flutter pub get
flutter gen-l10n          # regenerate localizations after editing lib/l10n/*.arb
```

**Android**
```bash
flutter run                                   # debug on a connected device
flutter build apk --release                   # release APK (use this for real use;
                                              # debug JIT-startup is slow on old phones)
flutter install --release                     # install that APK on a connected device
flutter build appbundle --release             # AAB for the Play Store upload
```

Release builds are signed from `android/key.properties` (gitignored — copy
`android/key.properties.example` and fill it in). Without that file the release
build falls back to the debug key, so `flutter run --release` still works.

**Other platforms** — Android is the only one in the repo. The iOS project was
removed rather than shipped half-validated; nothing in `lib/` is
Android-specific, so `flutter create --platforms=ios .` regenerates the
scaffold if iOS is ever picked up. Whoever does that will need to redeclare the
Bluetooth usage strings in `Info.plist` (universal_ble needs iOS 13.1+) and
pick a bundle identifier — the old one didn't match Android's
`ch.novaaccesslabs.scale`.

## Testing & analysis

```bash
flutter analyze        # must be clean
flutter test           # unit + widget tests
```

BLE, audio, TTS, and vibration cannot be unit-tested (no host hardware) and are
marked `MANUAL TEST REQUIRED` in source; verify those on a device.

## Localization

Add a language by:
1. Creating `lib/l10n/app_<code>.arb` (copy `app_en.arb` and translate every
   value).
2. Adding a TTS locale mapping for the code in `_localeByCode`
   (`lib/feedback/speech_service.dart`), so spoken announcements use the right
   voice.
3. `flutter gen-l10n`.

No other registration is needed — `AppLocalizations.supportedLocales` is
generated from the ARB files, and the app matches the device's locale
automatically (English fallback) with no in-app language picker to update.
Supported today: en, es, fr, de, it.

## Accessibility

Accessibility is a product requirement, not a feature. Screen-reader labels and
headers, large touch targets, no sliders, automatic light/dark theming, a
manual high-contrast toggle, reduced-motion support, and non-visual feedback
(audio/vibration/speech) are all first-class. The live weight and status are
read on screen-reader focus (not as chattering live regions) — automatic
announcements come from the pause-gated speech engine and the distinct
audio/haptic cues, routed through the accessibility layer when a screen reader
is active and the app's own TTS otherwise (`lib/feedback/speech_router.dart`).

Screen-reader behavior cannot be fully verified by widget tests: assert
`Semantics` labels and hints there, but do a manual TalkBack pass for
spoken output and focus order before shipping a screen change. Two properties
worth double-checking on a real device, not just in the simulator:
`MediaQuery.accessibleNavigation` only reflects reality once a screen reader
has actually queried the app's accessibility tree (not just a global OS
setting), and a live region only reaches a user reliably when it corresponds
to a persistent node whose content changes — a freshly-inserted region needs
an explicit announcement instead (see the `_announce*` helpers in
`lib/screens/connection_screen.dart` for the established pattern).

## Dependencies

`flutter pub outdated` to review; `flutter pub upgrade --major-versions` to bump.
BLE transport is `universal_ble` (BSD-3) — no license tier or per-connect
declaration required, unlike `flutter_blue_plus`.
