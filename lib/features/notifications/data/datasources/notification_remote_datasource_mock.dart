import '../../domain/entities/notification_entity.dart';
import 'notification_remote_datasource.dart';

/// Data dummy — di-self-design (nggak ada frame Figma buat ditranslate,
/// lihat catatan di `NotificationEntity`), tema notifikasi dipilih relevan
/// sama alur researcher yang udah jalan (progress survey, insentif keluar,
/// respondent masuk) + 1 contoh notifikasi sistem generik yang bakal
/// relevan buat role manapun.
///
/// Stateful/mutable (pola sama kayak `ResearcherRemoteDataSourceMock`
/// setelah update 2026-09-08) biar "tandai (semua) dibaca" beneran keliatan
/// efeknya pas list di-refresh, bukan cuma respon hardcoded yang sama tiap
/// fetch.
class NotificationRemoteDataSourceMock implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceMock() : _notifications = List.of(_seed);

  static const _networkDelay = Duration(milliseconds: 500);

  final List<NotificationEntity> _notifications;

  static final DateTime _now = DateTime(2026, 9, 8, 14, 30);

  static final List<NotificationEntity> _seed = [
    NotificationEntity(
      id: 'notif-1',
      type: NotificationType.respondent,
      title: 'Responden baru masuk',
      body: '"Survei Kepuasan Pelanggan" baru aja diisi 1 responden. Total sekarang 130/200.',
      createdAt: _now.subtract(const Duration(minutes: 12)),
    ),
    NotificationEntity(
      id: 'notif-2',
      type: NotificationType.payment,
      title: 'Insentif berhasil dikirim',
      body: 'Rp 15.000 udah otomatis kekirim ke 1 responden "Survei Kepuasan Pelanggan".',
      createdAt: _now.subtract(const Duration(hours: 2)),
    ),
    NotificationEntity(
      id: 'notif-3',
      type: NotificationType.survey,
      title: 'Survey mau deadline',
      body: '"Riset Pasar FMCG Jakarta" tinggal 5 hari lagi, progress baru 40%. Yuk di-share lagi.',
      createdAt: _now.subtract(const Duration(hours: 5)),
    ),
    NotificationEntity(
      id: 'notif-4',
      type: NotificationType.survey,
      title: 'Survey selesai',
      body: '"Survey Brand Awareness Q2" udah mencapai target 300 responden. Hasil siap diunduh.',
      createdAt: _now.subtract(const Duration(days: 1, hours: 3)),
      isRead: true,
    ),
    NotificationEntity(
      id: 'notif-5',
      type: NotificationType.system,
      title: 'Selamat datang di SurvMarkt',
      body: 'Lengkapi profil kamu biar survey makin gampang dipercaya responden.',
      createdAt: _now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    await Future.delayed(_networkDelay);
    final sorted = List.of(_notifications)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(_networkDelay);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      throw StateError('Notifikasi dengan id "$notificationId" tidak ditemukan.');
    }
    _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(_networkDelay);
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }
}
