import '../../../auth/domain/entities/user_entity.dart';
import '../entities/notification_entity.dart';

/// Kontrak layer domain buat fitur notifikasi — pola sama persis kayak
/// `ResearcherRepository`/`AuthRepository`: Presentation cuma kenal
/// interface ini, nggak tau/peduli implementasinya Mock atau Dio beneran.
///
/// Update 2026-09-09: `forRole` ditambahin ke [getNotifications]/
/// [markAllAsRead] (pola PERSIS sama kayak `WalletRepository.forRole`) —
/// permintaan user eksplisit: "notifikasi di responden juga
/// dipersonalisasi biar isinya sesuai apa apa yg ada di screen responden".
/// Sebelum ini SEMUA role (termasuk Responden) nampilin 5 notifikasi yang
/// isinya 100% dari sudut pandang Peneliti ("Responden baru masuk", dst) —
/// nggak masuk akal buat akun Responden. `forRole == null` atau `peneliti`
/// -> perilaku LAMA, nggak berubah (backward-compatible).
abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications({UserRole? forRole});

  /// Selalu cari lewat [notificationId], bukan index — sama kayak aturan
  /// `updateSurveyStatus`/`deleteSurvey` di `ResearcherRepository`.
  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead({UserRole? forRole});
}
