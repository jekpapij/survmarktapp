import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/survey_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 (Integration Engine) diimplementasi
/// beneran pakai Dio (`ResearcherRemoteDataSourceImpl`, mirror pola
/// `AuthRemoteDataSourceImpl`). Belum ada endpoint/model JSON di sini karena
/// belum ada backend buat dikontrak — baru ada [ResearcherRemoteDataSourceMock].
abstract class ResearcherRemoteDataSource {
  Future<DashboardStatsEntity> getDashboardStats();

  Future<List<SurveyEntity>> getSurveys();
}
