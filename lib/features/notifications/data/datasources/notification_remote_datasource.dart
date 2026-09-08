import '../../domain/entities/notification_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 diimplementasi beneran (push
/// notif via `firebase_messaging`, udah ada di `pubspec.yaml`). Baru ada
/// [NotificationRemoteDataSourceMock] buat sekarang.
abstract class NotificationRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications();

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead();
}
