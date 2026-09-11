# Darazinda Connect release ProGuard/R8 rules.
# android/app/build.gradle's release buildType references this file;
# it must exist even if mostly empty, or a --release build fails at
# the Gradle configuration step with "proguard-rules.pro does not
# exist". Flutter's own default rules already cover the Flutter
# engine; these are the extra keep rules needed for plugins used here
# that do reflection-based lookups R8 can't trace automatically.

# Firebase / Play Services use reflection for some model classes.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Drift/sqlite3 native bindings.
-keep class io.sqlite3.** { *; }

# Keep our own Kotlin platform-channel code (MainActivity) intact.
-keep class pk.darazindaconnect.app.** { *; }
