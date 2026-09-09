import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/datasources/admin_remote_datasource_mock.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/entities/audit_log_entry_entity.dart';
import '../../domain/entities/withdrawal_request_entity.dart';
import '../../domain/repositories/admin_repository.dart';

/// Belum ada cabang Dio beneran (nyusul CPMK 5) — pola sama kayak
/// `researcherRemoteDataSourceProvider`.
final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  // Stateful (in-memory mutable list withdrawal) — bukan `const`, biar
  // approve/reject beneran keliatan efeknya, pola sama kayak
  // `ResearcherRemoteDataSourceMock`.
  return AdminRemoteDataSourceMock();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider));
});

/// Gabungan stats + list withdrawal dalam 1 fetch (pola sama kayak
/// `ResearcherDashboardData`) — SENGAJA digabung (bukan 2 `FutureProvider`
/// independen) karena [withdrawalPendingCount]/[pendingPreview] di bawah
/// HARUS dihitung dari `withdrawals` yang SAMA yang datang bareng `stats`,
/// biar nggak ada 2 sumber data withdrawal yang bisa nggak sinkron (lihat
/// catatan lengkap di `AdminDashboardStatsEntity`).
class AdminDashboardData {
  const AdminDashboardData({required this.stats, required this.withdrawals});

  final AdminDashboardStatsEntity stats;
  final List<WithdrawalRequestEntity> withdrawals;

  int get withdrawalPendingCount =>
      withdrawals.where((w) => w.status == WithdrawalStatus.pending).length;

  /// 2 item pertama yang masih `pending` — buat card "PERLU TINDAKAN" di
  /// dashboard (Figma cuma nunjukin 2 baris preview, bukan semua).
  List<WithdrawalRequestEntity> get pendingPreview =>
      withdrawals.where((w) => w.status == WithdrawalStatus.pending).take(2).toList();
}

final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final results = await Future.wait([
    repository.getDashboardStats(),
    repository.getWithdrawals(),
  ]);
  return AdminDashboardData(
    stats: results[0] as AdminDashboardStatsEntity,
    withdrawals: results[1] as List<WithdrawalRequestEntity>,
  );
});

/// Fetch terpisah buat layar `admin-withdrawal` sendiri (list PENUH, bukan
/// cuma 2 preview) — `ref.invalidate` abis approve/reject bakal me-refresh
/// provider ini SEKALIGUS [adminDashboardProvider] (dipanggil bareng di
/// screen), biar kedua layar tetep konsisten satu sama lain.
final adminWithdrawalsProvider = FutureProvider<List<WithdrawalRequestEntity>>((ref) {
  return ref.watch(adminRepositoryProvider).getWithdrawals();
});

final adminAuditLogProvider = FutureProvider<List<AuditLogEntryEntity>>((ref) {
  return ref.watch(adminRepositoryProvider).getAuditLog();
});
