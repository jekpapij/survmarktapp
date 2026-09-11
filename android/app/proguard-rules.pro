# CPMK 6 (Security, CI/CD, & Store Distribution) — keep-rules R8/ProGuard.
#
# `isMinifyEnabled = true` (lihat android/app/build.gradle.kts) bikin R8
# ngestrip + ngobfuskasi apapun yang keliatan "nggak dipanggil langsung" dari
# kode Kotlin/Java — masalahnya beberapa library (Firebase, Play Services,
# Flutter embedding sendiri) manggil sebagian class-nya lewat reflection/JNI
# yang R8 nggak bisa lacak statis, jadi kalau nggak di-keep, app bisa
# CRASH DI RUNTIME (bukan gagal compile) begitu obfuskasi aktif — rules di
# bawah ini nyegah itu, disusun dari rekomendasi resmi Flutter + Firebase.

# --- Flutter engine & plugin embedding ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase (Auth, Firestore, Messaging) + Google Play Services ---
# CPMK 5 pakai firebase_auth, cloud_firestore, firebase_messaging,
# google_sign_in -- semua transitively butuh rules ini.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Flutter Secure Storage (JNI native ke Android Keystore) ---
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# --- Attribute umum yang dibutuhin reflection/generic-type resolution ---
# (Firestore/Gson-style POJO mapping, annotation-based library apapun).
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# --- Model app sendiri: aman di-keep field-name-nya biar nggak kena
# obfuskasi accidental kalau ada bagian kode yang serialize/deserialize
# lewat reflection generik (bukan cuma `fromJson`/`toJson` manual yang
# udah ada sekarang, jaga-jaga kalau nanti ganti ke library lain). ---
-keep class com.survmarkt.survmarkt.** { *; }
