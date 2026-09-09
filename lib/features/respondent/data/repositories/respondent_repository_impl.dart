import '../../domain/entities/respondent_activity_entity.dart';
import '../../domain/entities/survey_listing_entity.dart';
import '../../domain/repositories/respondent_repository.dart';
import '../datasources/respondent_remote_datasource.dart';

/// Passthrough tipis ke datasource — pola sama kayak
/// `ResearcherRepositoryImpl` (belum ada mapping Model->Entity karena belum
/// ada JSON beneran, baru [RespondentRemoteDataSourceMock]).
class RespondentRepositoryImpl implements RespondentRepository {
  const RespondentRepositoryImpl(this._remoteDataSource);

  final RespondentRemoteDataSource _remoteDataSource;

  @override
  Future<List<SurveyListingEntity>> getDiscoverSurveys() =>
      _remoteDataSource.getDiscoverSurveys();

  @override
  Future<List<RespondentActivityEntity>> getActivities() =>
      _remoteDataSource.getActivities();

  @override
  Future<void> submitSurveyResponse(SurveyListingEntity survey) =>
      _remoteDataSource.submitSurveyResponse(survey);
}
