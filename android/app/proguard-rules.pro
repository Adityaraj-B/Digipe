# Flutter & core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Cashfree Payment SDK — keep ALL cashfree packages
-keep class com.cashfree.** { *; }
-keep class com.cashfree.pg.** { *; }
-dontwarn com.cashfree.**

# Networking (used by Cashfree SDK internally)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Retrofit (used by Cashfree SDK)
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# Gson (used by Cashfree SDK for JSON serialization)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
