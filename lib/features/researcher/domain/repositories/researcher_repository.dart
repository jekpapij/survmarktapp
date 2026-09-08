import '../entities/dashboard_stats_entity.dart';
import '../entities/survey_entity.dart';

/// Kontrak layer domain buat fitur researcher — Presentation cuma kenal
/// interface ini, nggak tau/peduli implementasinya Mock atau Dio beneran
/// (pola yang sama persis kayak `AuthRepository`).
abstract class ResearcherRepository {
  Future<DashboardStatsEntity> getDashboardStats();

  Future<List<SurveyEntity>> getSurveys();

  /// Update 2026-09-08: buat modal "Kelola Survey" (pause/lanjutkan). Selalu
  /// cari survey lewat [surveyId], BUKAN index — lihat CLAUDE.md "Keputusan
  /// produk penting" soal bug klasik operasi survey pakai index array.
  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status);

  /// Soft delete — status jadi [SurveyStatus.deleted], tetap kesimpen buat
  /// audit (bukan dihapus fisik dari list), dan otomatis ke-filter keluar
  /// dari `getSurveys()`.
  Future<void> deleteSurvey(String surveyId);
}
