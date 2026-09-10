import 'package:flutter/material.dart';

/// CPMK 5 (Integration Engine) — dipasang ke `MaterialApp.router(
/// scaffoldMessengerKey: ...)` di `app.dart`, dipakai
/// `push_notification_providers.dart` buat nampilin SnackBar notifikasi
/// FOREGROUND (`FirebaseMessaging.onMessage`) DARI LUAR widget tree —
/// listener FCM hidup di level `Provider` (bukan widget), jadi nggak punya
/// akses `BuildContext`/`ScaffoldMessenger.of(context)` biasa.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
