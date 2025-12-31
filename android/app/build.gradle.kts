plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.company.blockerino"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.company.blockerino"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // CRITICAL: Disable minification to prevent Firebase classes from being stripped
            // If you need minification, add ProGuard rules instead
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
    
    // Firebase Authentication
    implementation("com.google.firebase:firebase-auth")
    
    // Cloud Firestore
    implementation("com.google.firebase:firebase-firestore")
    
    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging")
    
    // Firebase Crashlytics
    implementation("com.google.firebase:firebase-crashlytics")
    
    // Firebase Performance Monitoring
    implementation("com.google.firebase:firebase-perf")
    
    // Firebase Storage
    implementation("com.google.firebase:firebase-storage")
    
    // Firebase Remote Config
    implementation("com.google.firebase:firebase-config")
}
