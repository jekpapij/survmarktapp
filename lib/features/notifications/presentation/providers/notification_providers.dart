import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/datasources/notification_remote_datasource_mock.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

/// Belum ada cabang Dio beneran (nyusul CPMK 5, lewat `firebase_messaging`
/// buat push notif beneran) — sama kayak `researcherRemoteDataSourceProvider`,
/// jadi belum dipasang toggle `ApiConstants.useMockBackend`.
final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceMock();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationRemoteDataSourceProvider));
});

/// `FutureProvider` — `AsyncValue.when` di screen nanganin Loading/Error/
/// Success (CPMK 3), pola sama kayak `researcherDashboardProvider`.
///
/// Update 2026-09-09: baca role live dari `authNotifierProvider` & terusin
/// sebagai `forRole` — pola PERSIS sama kayak `walletProvider`, biar list
/// notifikasi otomatis "dipersonalisasi" sesuai role akun yang lagi login
/// (tanpa screen manapun perlu tau/nentuin sendiri role-nya).
final notificationsProvider = FutureProvider<List<NotificationEntity>>((ref) async {
  final role = ref.watch(authNotifierProvider).user?.role;
  return ref.watch(notificationRepositoryProvider).getNotifications(forRole: role);
});

/// Dipakai buat badge titik merah di bell icon app-bar — dihitung dari
/// `notificationsProvider` yang sama (bukan fetch terpisah), jadi tetep 1
/// sumber data. Default 0 kalau lagi loading/error (nggak nunjukin badge
/// keliru pas belum ada data).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
