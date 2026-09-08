import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/survey_entity.dart';
import '../../domain/repositories/researcher_repository.dart';
import '../datasources/researcher_remote_datasource.dart';

/// Passthrough tipis ke datasource — belum ada mapping Model->Entity karena
/// belum ada JSON beneran buat di-parse (baru [ResearcherRemoteDataSourceMock]
/// yang langsung return entity). Error handling (try/catch -> Either<Failure,
/// T>) juga belum ditambah di sini karena mock nggak pernah throw — nanti
/// disamain pola `AuthRepositoryImpl` pas datasource Dio beneran ditulis.
class ResearcherRepositoryImpl implements ResearcherRepository {
  const ResearcherRepositoryImpl(this._remoteDataSource);

  final ResearcherRemoteDataSource _remoteDataSource;

  @override
  Future<DashboardStatsEntity> getDashboardStats() => _remoteDataSource.getDashboardStats();

  @override
  Future<List<SurveyEntity>> getSurveys() => _remoteDataSource.getSurveys();

  @override
  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status) =>
      _remoteDataSource.updateSurveyStatus(surveyId, status);

  @override
  Future<void> deleteSurvey(String surveyId) => _remoteDataSource.deleteSurvey(surveyId);
}
