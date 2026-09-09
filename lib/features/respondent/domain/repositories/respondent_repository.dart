import '../entities/respondent_activity_entity.dart';
import '../entities/survey_listing_entity.dart';

/// Kontrak layer domain buat fitur respondent — Presentation cuma kenal
/// interface ini, pola sama persis kayak `ResearcherRepository`/
/// `AuthRepository`.
abstract class RespondentRepository {
  /// Search & filter kategori sengaja DITANGANIN DI CLIENT (local state di
  /// screen, lihat `respondent_discover_screen.dart`), bukan parameter di
  /// sini — konsisten sama pola "Estimasi Matching Responden" di
  /// `create-survey` yang juga mock/client-side, belum ada query database
  /// beneran (masih CPMK 3).
  Future<List<SurveyListingEntity>> getDiscoverSurveys();

  /// Update 2026-09-09: daftar aktivitas (survei yang udah disubmit) buat
  /// frame `respondent-activity` (node 77:2902) — tab Aktif/Riwayat
  /// DIFILTER DI CLIENT dari 1 list ini (lihat `RespondentActivityScreen`),
  /// bukan 2 endpoint kepisah, pola sama kayak search/filter kategori di
  /// Discover.
  Future<List<RespondentActivityEntity>> getActivities();

  /// Dipanggil dari tombol "Isi Survei" di `SurveyDetailModal` — nyatet
  /// aktivitas baru status Menunggu Verifikasi buat survei ini, biar
  /// nongol di tab Aktif. Belum beneran buka link survei eksternal (belum
  /// ada field link di `SurveyListingEntity`) — di luar scope CPMK 3.
  Future<void> submitSurveyResponse(SurveyListingEntity survey);
}
