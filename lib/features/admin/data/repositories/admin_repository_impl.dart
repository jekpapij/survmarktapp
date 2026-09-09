import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/entities/audit_log_entry_entity.dart';
import '../../domain/entities/withdrawal_request_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

/// Passthrough tipis ke datasource — pola sama kayak `ResearcherRepositoryImpl`/
/// `NotificationRepositoryImpl`.
class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  @override
  Future<AdminDashboardStatsEntity> getDashboardStats() => _remoteDataSource.getDashboardStats();

  @override
  Future<List<WithdrawalRequestEntity>> getWithdrawals() => _remoteDataSource.getWithdrawals();

  @override
  Future<void> approveWithdrawal(String withdrawalId) => _remoteDataSource.approveWithdrawal(withdrawalId);

  @override
  Future<void> rejectWithdrawal(String withdrawalId) => _remoteDataSource.rejectWithdrawal(withdrawalId);

  @override
  Future<List<AuditLogEntryEntity>> getAuditLog() => _remoteDataSource.getAuditLog();
}
