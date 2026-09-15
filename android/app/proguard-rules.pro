# R8/ProGuard rules for the release build.
# Flutter and its plugins ship their own consumer keep rules, so this file is
# intentionally minimal. Keep reflection-relevant attributes, and add app- or
# plugin-specific -keep rules here if a release build ever strips something
# that is needed at runtime.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
