import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/researcher_remote_datasource.dart';
import '../../data/datasources/researcher_remote_datasource_mock.dart';
import '../../data/repositories/researcher_repository_impl.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/survey_entity.dart';
import '../../domain/repositories/researcher_repository.dart';

/// Beda dari `authRemoteDataSourceProvider`: di sini belum ada cabang Dio
/// beneran buat di-toggle (`ResearcherRemoteDataSourceImpl` belum ditulis,
/// nyusul CPMK 5) — jadi belum dipasang `if (ApiConstants.useMockBackend)`
/// kayak auth (bakal jadi dead-code, karena cabang lain-nya belum ada buat
/// dituju). Pas Dio impl-nya ditulis nanti, ganti provider ini jadi
/// `if (ApiConstants.useMockBackend) return Mock(); return Impl(...);`
/// persis pola auth.
final researcherRemoteDataSourceProvider = Provider<ResearcherRemoteDataSource>((ref) {
  return const ResearcherRemoteDataSourceMock();
});

final researcherRepositoryProvider = Provider<ResearcherRepository>((ref) {
  return ResearcherRepositoryImpl(ref.watch(researcherRemoteDataSourceProvider));
});

/// Gabungan stats + list survey dalam 1 fetch — biar UI cuma perlu nanganin
/// 1 `AsyncValue` (1 state Loading/Error/Success), bukan 2 yang independen.
/// Mirip pola endpoint dashboard beneran yang biasanya emang 1 response
/// gabungan, bukan 2 request kepisah.
class ResearcherDashboardData {
  const ResearcherDashboardData({required this.stats, required this.surveys});

  final DashboardStatsEntity stats;
  final List<SurveyEntity> surveys;
}

final researcherDashboardProvider = FutureProvider<ResearcherDashboardData>((ref) async {
  final repository = ref.watch(researcherRepositoryProvider);
  final results = await Future.wait([
    repository.getDashboardStats(),
    repository.getSurveys(),
  ]);
  return ResearcherDashboardData(
    stats: results[0] as DashboardStatsEntity,
    surveys: results[1] as List<SurveyEntity>,
  );
});
