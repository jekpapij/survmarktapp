import '../entities/notification_entity.dart';

/// Kontrak layer domain buat fitur notifikasi — pola sama persis kayak
/// `ResearcherRepository`/`AuthRepository`: Presentation cuma kenal
/// interface ini, nggak tau/peduli implementasinya Mock atau Dio beneran.
abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();

  /// Selalu cari lewat [notificationId], bukan index — sama kayak aturan
  /// `updateSurveyStatus`/`deleteSurvey` di `ResearcherRepository`.
  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead();
}
