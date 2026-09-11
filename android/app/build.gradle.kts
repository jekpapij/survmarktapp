import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// CPMK 6 (Security & CI/CD) — signing config release BENERAN, gantiin
// signing pakai debug key (placeholder bawaan template Flutter, cuma buat
// `flutter run --release` lokal, TIDAK BOLEH dipakai buat AAB yang
// didistribusikan). Baca dari `android/key.properties` (LOCAL, git-ignored,
// lihat `android/key.properties.example` buat templatenya) kalau file itu
// ada di laptop lo; kalau nggak ada (kejadian ini di CI — GitHub Actions
// runner-nya nggak pernah dapet file lokal manapun), fallback ke environment
// variable (`KEYSTORE_PATH`/`KEYSTORE_PASSWORD`/`KEY_ALIAS`/`KEY_PASSWORD`,
// di-set dari GitHub Actions Secrets di `.github/workflows/build-release.
// yml`) — jadi 1 config Gradle yang sama jalan konsisten di 2 tempat tanpa
// pernah nyimpen kredensial sensitif apapun ke git. Checklist lengkap
// generate keystore-nya (`keytool`) ada di CLAUDE.md bagian CPMK 6.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingProp(propertyKey: String, envVar: String): String? =
    keystoreProperties.getProperty(propertyKey) ?: System.getenv(envVar)

val hasReleaseSigning = keystorePropertiesFile.exists() || System.getenv("KEYSTORE_PATH") != null

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

    signingConfigs {
        create("release") {
            val storePath = signingProp("storeFile", "KEYSTORE_PATH")
            if (storePath != null) {
                storeFile = file(storePath)
                storePassword = signingProp("storePassword", "KEYSTORE_PASSWORD")
                keyAlias = signingProp("keyAlias", "KEY_ALIAS")
                keyPassword = signingProp("keyPassword", "KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Update CPMK 6: pakai signing config "release" beneran kalau
            // keystore-nya udah ke-setup (lokal via key.properties ATAU CI
            // via env vars) — fallback ke debug key SENGAJA dipertahankan
            // biar `flutter run --release` tetap jalan buat testing lokal
            // sebelum keystore dibikin, TAPI AAB hasil fallback ini TIDAK
            // BOLEH didistribusikan (bukan signed pakai key produksi).
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // CPMK 6 (Security) — obfuskasi kode (R8) + shrink resource
            // buat release build. `proguard-rules.pro` (baru) isinya
            // keep-rules Flutter+Firebase standar, biar app nggak crash
            // runtime abis di-obfuskasi (lihat komentar lengkap di file
            // itu kenapa perlu).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
