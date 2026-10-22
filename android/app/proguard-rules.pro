# Flutter / Firebase keep rules for release (R8) builds.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**
