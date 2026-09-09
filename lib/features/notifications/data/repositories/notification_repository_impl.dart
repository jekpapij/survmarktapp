import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

/// Passthrough tipis ke datasource — pola sama kayak `ResearcherRepositoryImpl`.
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<List<NotificationEntity>> getNotifications({UserRole? forRole}) =>
      _remoteDataSource.getNotifications(forRole: forRole);

  @override
  Future<void> markAsRead(String notificationId) => _remoteDataSource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead({UserRole? forRole}) => _remoteDataSource.markAllAsRead(forRole: forRole);
}
