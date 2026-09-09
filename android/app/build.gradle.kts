plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase (Google Sign-In BENERAN) — plugin di-apply KONDISIONAL:
// `google-services.json` BELUM ada sampai setup Firebase Console kelar
// (bikin project, daftarin app Android package `com.survmarkt.survmarkt`
// + SHA-1 debug keystore, aktifin provider Google, download file ini —
// lihat checklist lengkap di CLAUDE.md/chat). Kalau plugin di-apply TANPA
// file itu ada, BUILD GAGAL TOTAL (bukan cuma fitur Google doang yang
// error) — makanya di-guard `if (file(...).exists())`. Begitu file itu
// ditaruh di folder `android/app/` ini, baris ini otomatis aktifin
// plugin-nya di build berikutnya, TANPA perlu ubah apa-apa lagi di sini.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.survmarkt.survmarkt"
    compileSdk = 36
    // Beberapa plugin (firebase_core, firebase_messaging, flutter_secure_storage,
    // path_provider_android, sqflite_android) butuh NDK 28.2.13676358 — versi
    // default dari Flutter lebih lama, jadi di-pin manual ke versi tertinggi
    // yang diminta (NDK backward-compatible per warning build).
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.survmarkt.survmarkt"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
