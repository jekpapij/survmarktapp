import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/utils/root_messenger.dart';
import 'features/notifications/presentation/providers/push_notification_providers.dart';
import 'router.dart';

class SurvMarktApp extends ConsumerWidget {
  const SurvMarktApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // CPMK 5 (Integration Engine) — "nyalain" push notification (registrasi
    // token FCM begitu user login + listener notifikasi foreground) buat
    // SEUMUR HIDUP app, bukan cuma pas 1 layar tertentu kebuka (beda dari
    // `walletAutoSyncProvider` yang sengaja di-watch per-layar Wallet).
    // Lihat catatan lengkap di `push_notification_providers.dart`.
    ref.watch(pushNotificationProvider);
    ref.watch(pushNotificationForegroundListenerProvider);

    return MaterialApp.router(
      title: 'SurvMarkt',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary600,
          primary: AppColors.primary600,
          surface: AppColors.primary50,
        ),
        scaffoldBackgroundColor: AppColors.primary50,
        // Material 3's default popup/menu surface (dipake DropdownButtonFormField
        // dkk) di-generate dari tonal palette seed, bukan dari `surface` di atas
        // — hasilnya sering gelap nggak nyambung sama tema terang. Di-pin manual
        // ke putih biar semua dropdown di app (Status, Pendidikan, dll — bukan
        // cuma role-select) konsisten terang.
        canvasColor: Colors.white,
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary600,
          brightness: Brightness.dark,
          surface: AppColors.darkBg,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        canvasColor: AppColors.darkSurface,
        fontFamily: 'Inter',
      ),
      themeMode: ThemeMode.system, // Ikut sistem, konsisten dengan web
      routerConfig: router,
    );
  }
}
