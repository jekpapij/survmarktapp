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
}
