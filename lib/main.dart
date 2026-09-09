import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';

/// CPMK 4 (Persistent Data & Offline-First): `Hive.initFlutter()` WAJIB
/// dipanggil sebelum ada Box yang dibuka di mana pun (lihat
/// `WalletLocalDataSourceImpl`) — makanya `main` sekarang `async` dan ini
/// jadi baris pertama sebelum `runApp`. Nggak pakai `@HiveType`/codegen
/// (`hive_generator`+`build_runner`) — semua Box di app ini nyimpen `String`
/// JSON manual (`jsonEncode`/`jsonDecode`), pola yang sama kayak
/// `AuthLocalDataSourceImpl` pakai Flutter Secure Storage. Alasan: environment
/// pengembangan nggak selalu bisa jalanin `build_runner` (butuh Dart SDK
/// lengkap + langkah generate manual), jadi Box `Box<String>` polos dipilih
/// biar app tetap bisa langsung di-`flutter run` tanpa langkah generate
/// tambahan — trade-off yang disengaja demi keandalan build.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    // Update — Google Sign-In BENERAN via Firebase: `initializeApp()`
    // di-`try/catch` SENGAJA. Sebelum setup Firebase Console kelar
    // (`google-services.json` belum ditaruh di `android/app/`), panggilan
    // ini bakal gagal — kalau dibiarin nge-throw ke luar, SELURUH app
    // crash di splash screen (bukan cuma fitur Google doang). Di-catch di
    // sini biar app tetap jalan normal buat semua fitur lain; cuma
    // "Masuk dengan Google" yang bakal gagal (nampilin SnackBar error,
    // BUKAN crash) sampai setup Firebase-nya beres. Lihat checklist
    // lengkap di `FirebaseGoogleAuthService`/CLAUDE.md.
    await Firebase.initializeApp();
  } catch (_) {}
  runApp(
    const ProviderScope(
      child: SurvMarktApp(),
    ),
  );
}
