import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/entities/audit_log_entry_entity.dart';
import '../../domain/entities/withdrawal_request_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 diimplementasi beneran pakai Dio
/// (`AdminRemoteDataSourceImpl`, mirror pola `AuthRemoteDataSourceImpl`).
/// Baru ada [AdminRemoteDataSourceMock] buat sekarang.
abstract class AdminRemoteDataSource {
  Future<AdminDashboardStatsEntity> getDashboardStats();

  Future<List<WithdrawalRequestEntity>> getWithdrawals();

  Future<void> approveWithdrawal(String withdrawalId);

  Future<void> rejectWithdrawal(String withdrawalId);

  Future<List<AuditLogEntryEntity>> getAuditLog();
}
