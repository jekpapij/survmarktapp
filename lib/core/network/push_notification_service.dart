import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// CPMK 5 (Integration Engine) — Panduan Pengerjaan poin 2 ("Integrasikan
/// fitur ... Push Notifications"). `firebase_messaging` udah nangkring di
/// `pubspec.yaml` dari jauh-jauh hari (komentar lama: "buat Push
/// Notification nanti") — baru beneran dipakein sekarang, project
/// Firebase-nya SAMA yang udah aktif dari setup Google Sign-In.
///
/// **Alur:** minta izin notifikasi (Android 13+ WAJIB minta eksplisit,
/// versi di bawahnya auto-granted) -> ambil token FCM device -> simpen ke
/// Firestore `users/{uid}.fcmToken`. Belum ada Cloud Function yang OTOMATIS
/// ngirim push (di luar scope malam ini — payload notifikasi biasanya
/// dipicu dari event server, mis. "survei kamu baru diverifikasi"/"insentif
/// masuk", yang butuh trigger Firestore terpisah) — buat BUKTI integrasi
/// CPMK 5 ini, testing dilakuin MANUAL lewat Firebase Console -> Cloud
/// Messaging -> "Send test message" (paste token dari sini), lihat checklist
/// lengkap di CLAUDE.md.
///
/// Notifikasi BACKGROUND/TERMINATED otomatis muncul di system tray Android
/// tanpa kode tambahan (bawaan plugin) — yang butuh ditangani manual cuma
/// notifikasi FOREGROUND (app lagi kebuka, `FirebaseMessaging.onMessage`),
/// lihat `push_notification_providers.dart`.
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  /// Best-effort SEPENUHNYA — dipanggil dari `push_notification_providers.dart`
  /// yang udah nge-`catchError` di pemanggilnya, jadi kegagalan di sini
  /// (device nggak punya Google Play Services valid, mis. emulator tanpa
  /// Play Store, atau user nolak izin notifikasi) TIDAK BOLEH sampai
  /// gangguin alur login/app lain sama sekali.
  Future<void> registerTokenFor(String uid) async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    // Token FCM device BISA berubah (reinstall app, clear data app, dst) —
    // listener ini nyimpen ulang otomatis kalau itu kejadian selama app
    // masih kebuka & user masih login. Subscription-nya sengaja nggak
    // di-cancel eksplisit (hidup selama proses app jalan) — cukup buat
    // scope demo CPMK 5 ini, bukan pola long-running-service produksi.
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));
  }

  Future<void> _saveToken(String uid, String token) {
    return _firestore.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }
}
