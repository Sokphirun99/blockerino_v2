# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firestore.** { *; }

# Keep Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Keep Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Keep Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }

# Keep Firebase Performance
-keep class com.google.firebase.perf.** { *; }

# Keep Firebase Storage
-keep class com.google.firebase.storage.** { *; }

# Keep Firebase Remote Config
-keep class com.google.firebase.remoteconfig.** { *; }

# Keep Firebase Cloud Messaging
-keep class com.google.firebase.messaging.** { *; }

# Keep Firebase Cloud Functions
-keep class com.google.firebase.functions.** { *; }

# Keep Gson classes (used by Firebase)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

