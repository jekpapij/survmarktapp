import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/push_notification_service.dart';
import '../../../../core/utils/root_messenger.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// CPMK 5 (Integration Engine) — wiring Riverpod buat Push Notification
/// (FCM). Ditaruh di modul `features/notifications/` (bukan `core/`) karena
/// ini presentation-layer glue (nyentuh `BuildContext`/`ScaffoldMessenger`
/// lewat `rootScaffoldMessengerKey` & baca `authNotifierProvider`) — logic
/// murninya (request permission, simpen token) ada di
/// `core/network/push_notification_service.dart`.
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// "Nyalain" registrasi token FCM begitu user AUTHENTICATED — di-watch
/// SEKALI dari root widget `SurvMarktApp` (`app.dart`), bukan per-layar,
/// karena relevan di SELURUH app (beda dari `walletAutoSyncProvider` yang
/// scope-nya cuma layar Wallet). No-op total kalau `useFirebaseBackend`
/// masih `false` (belum ada `users/{uid}` beneran buat disimpenin token-nya)
/// — safety-net yang sama kayak fitur CPMK 5 lain.
final pushNotificationProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    if (!ApiConstants.useFirebaseBackend) return;
    if (next.status != AuthStatus.authenticated || next.user == null) return;
    // Best-effort — device tanpa Google Play Services valid (mis. emulator
    // tanpa Play Store) atau user nolak izin notifikasi TIDAK BOLEH sampai
    // gangguin alur login. Lihat catatan lengkap di
    // `PushNotificationService.registerTokenFor`.
    ref.read(pushNotificationServiceProvider).registerTokenFor(next.user!.id).catchError((Object _) {});
  });
});

/// Notifikasi FOREGROUND (app lagi kebuka) BUKAN otomatis muncul di system
/// tray Android (perilaku bawaan FCM — beda dari background/terminated yang
/// otomatis) — listener ini yang nampilin SnackBar manual lewat
/// `rootScaffoldMessengerKey` (listener-nya hidup di level Provider, nggak
/// punya `BuildContext` widget biasa). Global (bukan tergantung auth state)
/// — cukup di-subscribe SEKALI seumur hidup app.
final pushNotificationForegroundListenerProvider = Provider<void>((ref) {
  if (!ApiConstants.useFirebaseBackend) return;
  FirebaseMessaging.onMessage.listen((message) {
    final title = message.notification?.title;
    final body = message.notification?.body;
    final text = [title, body].where((s) => s != null && s.isNotEmpty).join(' — ');
    if (text.isEmpty) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
  });
});
