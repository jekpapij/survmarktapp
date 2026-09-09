import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/notification_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 diimplementasi beneran (push
/// notif via `firebase_messaging`, udah ada di `pubspec.yaml`). Baru ada
/// [NotificationRemoteDataSourceMock] buat sekarang.
abstract class NotificationRemoteDataSource {
  // Update 2026-09-09: `forRole` — lihat catatan lengkap di
  // `NotificationRepository`.
  Future<List<NotificationEntity>> getNotifications({UserRole? forRole});

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead({UserRole? forRole});
}
