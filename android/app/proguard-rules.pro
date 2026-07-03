# SECTION 12: ProGuard rules to keep essential classes
-keep class com.cashfree.** { *; }
-keep class io.flutter.** { *; }
-keep class okhttp3.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
