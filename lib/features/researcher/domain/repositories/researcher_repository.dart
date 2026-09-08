import '../entities/dashboard_stats_entity.dart';
import '../entities/survey_entity.dart';

/// Kontrak layer domain buat fitur researcher — Presentation cuma kenal
/// interface ini, nggak tau/peduli implementasinya Mock atau Dio beneran
/// (pola yang sama persis kayak `AuthRepository`).
abstract class ResearcherRepository {
  Future<DashboardStatsEntity> getDashboardStats();

  Future<List<SurveyEntity>> getSurveys();
}
