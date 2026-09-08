import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

/// Passthrough tipis ke datasource — pola sama kayak `ResearcherRepositoryImpl`.
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<List<NotificationEntity>> getNotifications() => _remoteDataSource.getNotifications();

  @override
  Future<void> markAsRead(String notificationId) => _remoteDataSource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead() => _remoteDataSource.markAllAsRead();
}
