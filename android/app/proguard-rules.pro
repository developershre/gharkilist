# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# SQFlite & SQLite
-keep class com.tekartik.sqflite.** { *; }

# Image Picker & Share Plus
-keep class com.mr.flutter.plugin.imagepicker.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
