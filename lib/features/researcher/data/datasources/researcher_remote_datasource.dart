import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/survey_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 (Integration Engine) diimplementasi
/// beneran pakai Dio (`ResearcherRemoteDataSourceImpl`, mirror pola
/// `AuthRemoteDataSourceImpl`). Belum ada endpoint/model JSON di sini karena
/// belum ada backend buat dikontrak — baru ada [ResearcherRemoteDataSourceMock].
abstract class ResearcherRemoteDataSource {
  Future<DashboardStatsEntity> getDashboardStats();

  Future<List<SurveyEntity>> getSurveys();

  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status);

  Future<void> deleteSurvey(String surveyId);

  Future<SurveyEntity> createSurvey({
    required String title,
    required String category,
    required String description,
    required String surveyLink,
    required int durationMinutes,
    required int incentiveAmount,
    required int targetCount,
    required String targetLabel,
    required DateTime deadlineDate,
    required bool featured,
  });
}
