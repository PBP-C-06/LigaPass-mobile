import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val googleClientId: String =
    (project.findProperty("GOOGLE_CLIENT_ID") as String?)
        ?: System.getenv("GOOGLE_CLIENT_ID")
        ?: "496589546073-lhasinbg2db22bkti40suvgaqjqti4t2.apps.googleusercontent.com"

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    val bundledKeystore = rootProject.file("../release-keystore.jks")
    if (bundledKeystore.exists()) {
        keystoreProperties["storeFile"] = bundledKeystore.absolutePath
        keystoreProperties["storePassword"] =
            System.getenv("RELEASE_KEYSTORE_PASSWORD") ?: "admin12345adminligapass"
        keystoreProperties["keyPassword"] =
            System.getenv("RELEASE_KEY_PASSWORD") ?: "admin12345adminligapass"
        keystoreProperties["keyAlias"] = System.getenv("RELEASE_KEY_ALIAS") ?: "release"
    }
}
val hasReleaseKeystore = keystoreProperties["storeFile"] != null

android {
    namespace = "com.example.ligapass"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ligapass"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleClientId"] = googleClientId
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
            } else {
                storeFile = null
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
