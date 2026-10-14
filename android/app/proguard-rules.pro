# Keep Facebook Infer annotation classes
-keep class com.facebook.infer.annotation.** { *; }
-dontwarn com.facebook.infer.annotation.**

-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# WorkManager / Room (pulled in by AdMob). R8 otherwise drops WorkDatabase_Impl.
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.work.**

# Play scans the release dex for these Android 15 window calls. They are
# no-ops on API 35+, and the activity theme paints transparent bars on older
# releases, so the Flutter embedding's invokes can be dropped.
-assumenosideeffects class android.view.Window {
    void setStatusBarColor(int);
    void setNavigationBarColor(int);
    void setNavigationBarDividerColor(int);
}