import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/notification_entity.dart';
import 'notification_remote_datasource.dart';

/// Data dummy — di-self-design (nggak ada frame Figma buat ditranslate,
/// lihat catatan di `NotificationEntity`). [_researcherSeed] temanya relevan
/// sama alur Peneliti (progress survey, insentif keluar, respondent masuk).
///
/// **Update 2026-09-09 — role-aware, [_respondentSeed] baru:** sebelum ini
/// SEMUA role (termasuk Responden) nampilin [_researcherSeed] doang — dari
/// sudut pandang Peneliti, nggak masuk akal buat akun Responden (laporan
/// user: "notifikasi di responden juga dipersonalisasi biar isinya sesuai
/// apa apa yg ada di screen responden"). [_respondentSeed] isinya
/// CROSS-REFERENCE sengaja ke data yang UDAH ada di mock lain — judul
/// survei & nominal Rupiah-nya DIJAGA SAMA PERSIS kayak
/// `RespondentRemoteDataSourceMock._activities` (tab Aktivitas) &
/// `WalletRemoteDataSourceMock._respondentTransactions` (tab Wallet) —
/// biar notifikasi beneran "sesuai apa yang ada di screen responden lain",
/// bukan cuma tema doang. Manual disinkronin (belum ada 1 sumber kebenaran
/// beneran karena 3-3nya masih mock data terpisah per fitur — pola sama
/// kayak catatan "dua-duanya dijaga MANUAL" di `WalletRemoteDataSourceMock`
/// buat saldo dashboard vs wallet).
///
/// **Deviasi disadari (scope dipersempit):** dipilih pendekatan SEED
/// STATIS-tapi-konsisten, BUKAN push notifikasi live tiap "Isi Survei"
/// (walau itu juga mungkin) — cukup buat ngatasin keluhan literal user
/// (isi notifikasi nggak relevan sama sekali buat Responden), tanpa nambah
/// coupling lintas fitur (`NotificationRemoteDataSourceMock` baca state
/// internal `RespondentRemoteDataSourceMock`/`WalletRemoteDataSourceMock`
/// bakal ngelanggar batas Clean Architecture antar-fitur).
///
/// Stateful/mutable (pola sama kayak `ResearcherRemoteDataSourceMock`
/// setelah update 2026-09-08) biar "tandai (semua) dibaca" beneran keliatan
/// efeknya pas list di-refresh, bukan cuma respon hardcoded yang sama tiap
/// fetch. Kedua seed digabung jadi 1 list internal, dibedain lewat prefix
/// id (`notif-` vs `rnotif-`) — pola sama kayak `seed-activity-N` vs
/// `discover-N` di `RespondentRemoteDataSourceMock`.
class NotificationRemoteDataSourceMock implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceMock() : _notifications = List.of([..._researcherSeed, ..._respondentSeed]);

  static const _networkDelay = Duration(milliseconds: 500);

  final List<NotificationEntity> _notifications;

  static final DateTime _now = DateTime(2026, 9, 8, 14, 30);

  static final List<NotificationEntity> _researcherSeed = [
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

  static final List<NotificationEntity> _respondentSeed = [
    NotificationEntity(
      id: 'rnotif-1',
      type: NotificationType.survey,
      title: 'Survei diverifikasi',
      body: '"Survei Kebiasaan Belanja Online Gen Z" berhasil diverifikasi — insentif Rp 15.000 otomatis masuk ke Wallet kamu.',
      createdAt: _now.subtract(const Duration(hours: 3)),
    ),
    NotificationEntity(
      id: 'rnotif-2',
      type: NotificationType.payment,
      title: 'Insentif masuk ke Wallet',
      body: 'Rp 25.000 dari survei "Kepuasan Layanan Streaming" udah nambah ke saldo Wallet kamu.',
      createdAt: _now.subtract(const Duration(hours: 6)),
    ),
    NotificationEntity(
      id: 'rnotif-3',
      type: NotificationType.survey,
      title: 'Survei ditolak',
      body: '"Persepsi Energi Terbarukan di Kalangan Milenial" nggak lolos verifikasi — insentif Rp 10.000 nggak jadi dikreditkan. Cek detail di tab Aktivitas.',
      createdAt: _now.subtract(const Duration(days: 1)),
    ),
    NotificationEntity(
      id: 'rnotif-4',
      type: NotificationType.payment,
      title: 'Penarikan dana berhasil',
      body: 'Penarikan Rp 100.000 ke Bank BCA berhasil diproses.',
      createdAt: _now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationEntity(
      id: 'rnotif-5',
      type: NotificationType.survey,
      title: 'Survei baru cocok buat kamu',
      body: '"Survei Kebiasaan Belanja Online Gen Z" cocok sama profil kamu — insentif Rp 15.000, cuma 15 menit. Yuk isi sebelum kuotanya penuh.',
      createdAt: _now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
    NotificationEntity(
      id: 'rnotif-6',
      type: NotificationType.system,
      title: 'Lengkapi profil kamu',
      body: 'Data Jenis Kelamin/Usia/Status/Domisili kamu masih ada yang kosong — lengkapi di tab Profil biar makin banyak survei yang cocok.',
      createdAt: _now.subtract(const Duration(days: 5)),
      isRead: true,
    ),
  ];

  static bool _isRespondentId(String id) => id.startsWith('rnotif-');

  @override
  Future<List<NotificationEntity>> getNotifications({UserRole? forRole}) async {
    await Future.delayed(_networkDelay);
    final scoped = _notifications.where((n) => _isRespondentId(n.id) == (forRole == UserRole.responden)).toList();
    scoped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return scoped;
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
  Future<void> markAllAsRead({UserRole? forRole}) async {
    await Future.delayed(_networkDelay);
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (_isRespondentId(n.id) == (forRole == UserRole.responden)) {
        _notifications[i] = n.copyWith(isRead: true);
      }
    }
  }
}
