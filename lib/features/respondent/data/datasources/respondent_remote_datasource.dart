import '../../domain/entities/respondent_activity_entity.dart';
import '../../domain/entities/survey_listing_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 diimplementasi beneran pakai Dio
/// (`RespondentRemoteDataSourceImpl`, mirror pola
/// `AuthRemoteDataSourceImpl`/`ResearcherRemoteDataSource`). Belum ada
/// endpoint/model JSON di sini karena belum ada backend buat dikontrak —
/// baru ada [RespondentRemoteDataSourceMock].
abstract class RespondentRemoteDataSource {
  Future<List<SurveyListingEntity>> getDiscoverSurveys();

  Future<List<RespondentActivityEntity>> getActivities();

  Future<void> submitSurveyResponse(SurveyListingEntity survey);
}
