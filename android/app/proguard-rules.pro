# Keep Facebook Infer annotation classes
-keep class com.facebook.infer.annotation.** { *; }
-dontwarn com.facebook.infer.annotation.**

-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception