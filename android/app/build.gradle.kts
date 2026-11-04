plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 1. Namespace yahan aise likha jata hai
    namespace = "com.example.india_serial_hub"
    compileSdk = flutter.compileSdkVersion

    // NDK 28 required by jni plugin (wakelock_plus)
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // 2. Application ID mein '=' lagana zaroori hai
        applicationId = "com.example.india_serial_hub"
        // minSdk 21 = Android 5.0 — purane LED/Android TV par bhi app chalegi
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}