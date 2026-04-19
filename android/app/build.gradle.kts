plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

val hasReleaseKeystore = if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))

    val keyAlias = keystoreProperties.getProperty("keyAlias")?.trim()
    val keyPassword = keystoreProperties.getProperty("keyPassword")?.trim()
    val storePassword = keystoreProperties.getProperty("storePassword")?.trim()
    val storeFilePath = keystoreProperties.getProperty("storeFile")?.trim()

    val hasAllValues = !keyAlias.isNullOrEmpty() &&
        !keyPassword.isNullOrEmpty() &&
        !storePassword.isNullOrEmpty() &&
        !storeFilePath.isNullOrEmpty()

    val storeFileExists = hasAllValues && file(storeFilePath!!).exists()

    hasAllValues && storeFileExists
} else {
    false
}

android {
    namespace = "com.tartelea.app"
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
        applicationId = "com.tartelea.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // A release APK is still installable without committing a keystore.
                // Dokploy/CI should provide `android/key.properties` + a `.jks` via secrets for production signing.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
