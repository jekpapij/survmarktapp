import '../entities/admin_dashboard_stats_entity.dart';
import '../entities/audit_log_entry_entity.dart';
import '../entities/withdrawal_request_entity.dart';

/// Kontrak layer domain buat fitur admin — Presentation cuma kenal
/// interface ini, pola sama persis kayak `ResearcherRepository`/
/// `RespondentRepository`.
abstract class AdminRepository {
  Future<AdminDashboardStatsEntity> getDashboardStats();

  Future<List<WithdrawalRequestEntity>> getWithdrawals();

  /// Selalu cari withdrawal lewat [withdrawalId], BUKAN index — lihat
  /// CLAUDE.md "Keputusan produk penting" soal bug klasik operasi pakai
  /// index array (pola sama kayak `updateSurveyStatus`).
  Future<void> approveWithdrawal(String withdrawalId);

  Future<void> rejectWithdrawal(String withdrawalId);

  Future<List<AuditLogEntryEntity>> getAuditLog();
}
