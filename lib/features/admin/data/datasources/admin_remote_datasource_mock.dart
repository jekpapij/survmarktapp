import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/entities/audit_log_entry_entity.dart';
import '../../domain/entities/withdrawal_request_entity.dart';
import 'admin_remote_datasource.dart';

/// Data dummy — isinya nyamain contoh yang ada di 3 frame Figma admin yang
/// punya list (`admin-dashboard` node `88:52`, `admin-withdrawal` node
/// `86:52`, `admin-audit-log` node `86:170`; `admin-login`/`admin-profil`
/// nggak punya list data).
///
/// Stateful/mutable dari AWAL (pola "stateful-mock-from-the-start" — lihat
/// CLAUDE.md) — `_withdrawals` WAJIB mutable karena approve/reject beneran
/// harus mindahin item antar tab Pending/Disetujui/Ditolak di
/// `admin-withdrawal`, bukan cuma respon hardcoded sama tiap fetch. Cari
/// withdrawal SELALU lewat `id` (`indexWhere`), bukan index array — pola
/// sama kayak `ResearcherRemoteDataSourceMock`.
class AdminRemoteDataSourceMock implements AdminRemoteDataSource {
  AdminRemoteDataSourceMock() : _withdrawals = List.of(_seedWithdrawals);

  static const _networkDelay = Duration(milliseconds: 700);

  final List<WithdrawalRequestEntity> _withdrawals;

  /// 7 withdrawal, SEMUA seed `pending` — angka "7" ini SENGAJA disamain
  /// PERSIS sama stat card "WITHDRAWAL 7" di `admin-dashboard` (lihat
  /// catatan lengkap di `AdminDashboardStatsEntity`, kenapa `withdrawalPending`
  /// dihitung LIVE dari list ini, bukan field statis terpisah).
  ///
  /// 4 item pertama (`wd-1`..`wd-4`) PERSIS 4 contoh card di Figma
  /// `admin-withdrawal` (termasuk urutan — `wd-1`/`wd-2` juga jadi preview
  /// "PERLU TINDAKAN" di dashboard). `wd-5`..`wd-7` DIKARANG (nggak ada di
  /// Figma) cuma buat genapin total jadi 7 sesuai stat dashboard — nama &
  /// metode pembayaran sengaja beda-beda, konsisten sama variasi 4 contoh
  /// aslinya.
  static final List<WithdrawalRequestEntity> _seedWithdrawals = [
    WithdrawalRequestEntity(
      id: 'wd-1',
      respondentName: 'Siti Nurhaliza',
      destinationLabel: 'Bank BCA •••1234',
      amount: 250000,
      requestDate: DateTime(2026, 8, 28),
      status: WithdrawalStatus.pending,
    ),
    WithdrawalRequestEntity(
      id: 'wd-2',
      respondentName: 'Budi Santoso',
      destinationLabel: 'OVO •••8876',
      amount: 150000,
      requestDate: DateTime(2026, 8, 28),
      status: WithdrawalStatus.pending,
    ),
    WithdrawalRequestEntity(
      id: 'wd-3',
      respondentName: 'Dewi Lestari',
      destinationLabel: 'Bank Mandiri •••5567',
      amount: 75000,
      requestDate: DateTime(2026, 8, 27),
      status: WithdrawalStatus.pending,
    ),
    WithdrawalRequestEntity(
      id: 'wd-4',
      respondentName: 'Rizky Aditya',
      destinationLabel: 'GoPay •••3345',
      amount: 200000,
      requestDate: DateTime(2026, 8, 27),
      status: WithdrawalStatus.pending,
    ),
    WithdrawalRequestEntity(
      id: 'wd-5',
      respondentName: 'Nadia Kusuma',
      destinationLabel: 'Bank BNI •••7788',
      amount: 100000,
      requestDate: DateTime(2026, 8, 26),
      status: WithdrawalStatus.pending,
    ),
    WithdrawalRequestEntity(
      id: 'wd-6',
      respondentName: 'Fajar Ramadhan',
      destinationLabel: 'DANA •••4432',
      amount: 50000,
      requestDate: DateTime(2026, 8, 26),
      status: WithdrawalStatus.pending,
    ),
    WithdrawalRequestEntity(
      id: 'wd-7',
      respondentName: 'Lina Marlina',
      destinationLabel: 'Bank BRI •••9012',
      amount: 180000,
      requestDate: DateTime(2026, 8, 25),
      status: WithdrawalStatus.pending,
    ),
  ];

  /// 5 audit-card PERSIS Figma `admin-audit-log` — deskripsi CROSS-REFERENCE
  /// sengaja ke mock lain yang udah ada biar konsisten lintas fitur (pola
  /// sama kayak `NotificationRemoteDataSourceMock._respondentSeed`):
  /// "Riset Pasar FMCG Jakarta"/"UX Testing Aplikasi Mobile"/"Survey Brand
  /// Awareness Q2" = 3 judul survey PERSIS dari `ResearcherRemoteDataSourceMock`
  /// (survey-3/survey-2/survey-4). `audit-2` & `audit-3` dijadiin seed buat
  /// `NotificationRemoteDataSourceMock._adminSeed` juga.
  static final List<AuditLogEntryEntity> _auditLog = [
    AuditLogEntryEntity(
      id: 'audit-1',
      actionType: AuditActionType.withdrawalApproved,
      description: 'Withdrawal Rp 250.000 untuk Siti Nurhaliza disetujui',
      actorLabel: 'oleh Admin Utama',
      timestamp: DateTime(2026, 8, 31, 14, 20),
    ),
    AuditLogEntryEntity(
      id: 'audit-2',
      actionType: AuditActionType.deleteSurvey,
      description: 'Survey "Riset Pasar FMCG Jakarta" dihapus',
      actorLabel: 'oleh Andi Wijaya (Peneliti)',
      timestamp: DateTime(2026, 8, 31, 9, 10),
    ),
    AuditLogEntryEntity(
      id: 'audit-3',
      actionType: AuditActionType.roleChanged,
      description: 'Role akun Rina Marlina diubah dari Responden ke Peneliti',
      actorLabel: 'oleh Admin Utama',
      timestamp: DateTime(2026, 8, 30, 16, 45),
    ),
    AuditLogEntryEntity(
      id: 'audit-4',
      actionType: AuditActionType.surveyPaused,
      description: 'Survey "UX Testing Aplikasi Mobile" dijeda',
      actorLabel: 'oleh Citra Ayu (Peneliti)',
      timestamp: DateTime(2026, 8, 29, 11, 0),
    ),
    AuditLogEntryEntity(
      id: 'audit-5',
      actionType: AuditActionType.surveyClosed,
      description: 'Survey "Survey Brand Awareness Q2" ditutup otomatis (kuota tercapai)',
      actorLabel: 'oleh Sistem',
      timestamp: DateTime(2026, 8, 28, 20, 15),
    ),
  ];

  @override
  Future<AdminDashboardStatsEntity> getDashboardStats() async {
    await Future.delayed(_networkDelay);
    return const AdminDashboardStatsEntity(
      revenue: 8450000,
      weeklyChart: [60, 40, 80, 55, 90, 70, 45],
      totalTransaksi: 312,
      rataRataPerHari: 272000,
      totalPengguna: 2480,
      surveyAktif: 86,
      surveyDitutupBulanIni: 34,
    );
  }

  @override
  Future<List<WithdrawalRequestEntity>> getWithdrawals() async {
    await Future.delayed(_networkDelay);
    return List.unmodifiable(_withdrawals);
  }

  @override
  Future<void> approveWithdrawal(String withdrawalId) async {
    await Future.delayed(_networkDelay);
    final index = _withdrawals.indexWhere((w) => w.id == withdrawalId);
    if (index == -1) {
      throw StateError('Withdrawal dengan id "$withdrawalId" tidak ditemukan.');
    }
    _withdrawals[index] = _withdrawals[index].copyWith(status: WithdrawalStatus.disetujui);
  }

  @override
  Future<void> rejectWithdrawal(String withdrawalId) async {
    await Future.delayed(_networkDelay);
    final index = _withdrawals.indexWhere((w) => w.id == withdrawalId);
    if (index == -1) {
      throw StateError('Withdrawal dengan id "$withdrawalId" tidak ditemukan.');
    }
    _withdrawals[index] = _withdrawals[index].copyWith(status: WithdrawalStatus.ditolak);
  }

  @override
  Future<List<AuditLogEntryEntity>> getAuditLog() async {
    await Future.delayed(_networkDelay);
    return _auditLog;
  }
}
