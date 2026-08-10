# Flutter engine + embedding: referenced reflectively from native code.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ML Kit barcode scanning (mobile_scanner). The text-recognition options classes
# are referenced reflectively by Play Services and warn at shrink time even though
# this app only uses barcode scanning.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Keep annotated Play Services entry points.
-keep @com.google.android.gms.common.annotation.KeepName class *
-keepclassmembers class * {
    @com.google.android.gms.common.annotation.KeepName *;
}

# Strip all android.util.Log calls from release builds so nothing the app logs can
# leak to logcat, regardless of what future code adds.
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
