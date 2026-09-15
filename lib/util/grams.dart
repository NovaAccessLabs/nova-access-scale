/// Formatting for the app's 0.1 g feedback precision.
///
/// The target is set in whole grams, but the live weight, the remaining /
/// over-target amounts, and the spoken announcements are reported to 0.1 g.
library;

/// Formats [grams] for display/announcement at 0.1 g precision, e.g. "2.3".
String formatGrams(double grams) => grams.toStringAsFixed(1);

/// Starting value for the target stepper when no target has been set yet.
///
/// A general-purpose kitchen amount, not tied to any one recipe or ingredient:
/// the app weighs flour, sugar, pasta, or coffee equally. Users step from here
/// in 1 g / 10 g increments, so this only needs to be a neutral middle ground.
const int defaultTargetGrams = 100;
