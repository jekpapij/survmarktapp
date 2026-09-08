import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/survey_entity.dart';
import 'researcher_remote_datasource.dart';

/// Data dummy — isinya PERSIS nyamain contoh yang ada di frame Figma
/// `researcher-dashboard` (get_design_context, node 77:2446), termasuk 4
/// contoh state survey (OPEN/PAUSED/FEATURED+ExpiringSoon/CLOSED) yang udah
/// didokumentasiin di CLAUDE.md "Mockup referensi". Toggle Mock<->Dio nyusul
/// pola yang sama kayak auth: `ApiConstants.useMockBackend` lewat provider.
class ResearcherRemoteDataSourceMock implements ResearcherRemoteDataSource {
  const ResearcherRemoteDataSourceMock();

  static const _networkDelay = Duration(milliseconds: 700);

  @override
  Future<DashboardStatsEntity> getDashboardStats() async {
    await Future.delayed(_networkDelay);
    return const DashboardStatsEntity(
      totalSurvey: 14,
      totalExpense: 6200000,
      targetResponden: 1840,
      saldo: 350000,
    );
  }

  @override
  Future<List<SurveyEntity>> getSurveys() async {
    await Future.delayed(_networkDelay);
    return const [
      SurveyEntity(
        id: 'survey-1',
        title: 'Survei Kepuasan Pelanggan',
        status: SurveyStatus.open,
        progressPercent: 65,
        views: 324,
        conversionPercent: 18.2,
        metaKind: SurveyMetaKind.deadline,
        metaText: 'Deadline: 12 hari lagi',
      ),
      SurveyEntity(
        id: 'survey-2',
        title: 'UX Testing Aplikasi Mobile',
        status: SurveyStatus.paused,
        progressPercent: 80,
        views: 198,
        conversionPercent: 31.4,
        metaKind: SurveyMetaKind.paused,
        metaText: 'Dijeda 3 hari lalu',
      ),
      SurveyEntity(
        id: 'survey-3',
        title: 'Riset Pasar FMCG Jakarta',
        status: SurveyStatus.open,
        progressPercent: 40,
        views: 512,
        conversionPercent: 22.7,
        metaKind: SurveyMetaKind.deadline,
        metaText: 'Deadline: 5 hari lagi',
        featured: true,
        expiringSoon: true,
      ),
      SurveyEntity(
        id: 'survey-4',
        title: 'Survey Brand Awareness Q2',
        status: SurveyStatus.closed,
        progressPercent: 100,
        views: 450,
        conversionPercent: 44.4,
        metaKind: SurveyMetaKind.completed,
        metaText: 'Selesai · 6 hari lalu',
      ),
    ];
  }
}
