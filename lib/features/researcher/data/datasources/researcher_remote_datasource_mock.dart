import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/entities/survey_entity.dart';
import 'researcher_remote_datasource.dart';

/// Data dummy — isinya PERSIS nyamain contoh yang ada di frame Figma
/// `researcher-dashboard` (get_design_context, node 77:2446), termasuk 4
/// contoh state survey (OPEN/PAUSED/FEATURED+ExpiringSoon/CLOSED) yang udah
/// didokumentasiin di CLAUDE.md "Mockup referensi". Toggle Mock<->Dio nyusul
/// pola yang sama kayak auth: `ApiConstants.useMockBackend` lewat provider.
///
/// Update 2026-09-08: nggak lagi `const`/immutable — buat ndukung modal
/// "Kelola Survey" (pause/lanjutkan/hapus), datasource ini sekarang nyimpen
/// `_surveys` sebagai in-memory mutable list, disimulasiin persis kayak
/// server beneran yang state-nya berubah abis mutation. Cari survey SELALU
/// lewat `id` (`indexWhere`), bukan asumsi posisi array — lihat CLAUDE.md
/// "Keputusan produk penting" soal bug klasik ini.
class ResearcherRemoteDataSourceMock implements ResearcherRemoteDataSource {
  ResearcherRemoteDataSourceMock() : _surveys = List.of(_seedSurveys);

  static const _networkDelay = Duration(milliseconds: 700);

  final List<SurveyEntity> _surveys;

  // Tanggal seed relatif ke "hari ini" mock (2026-09-08) biar `metaText`
  // statis ("Deadline: 12 hari lagi", dst.) tetep konsisten sama
  // `Formatters.relativeDays(deadlineDate)` yang dihitung live di modal.
  static final List<SurveyEntity> _seedSurveys = [
    SurveyEntity(
      id: 'survey-1',
      title: 'Survei Kepuasan Pelanggan',
      category: 'Customer Experience',
      status: SurveyStatus.open,
      durationMinutes: 10,
      incentiveAmount: 15000,
      targetLabel: 'Pelanggan Aktif 18-45 tahun',
      deadlineDate: DateTime(2026, 9, 20),
      respondentCount: 130,
      targetCount: 200,
      views: 324,
      conversionPercent: 18.2,
      metaKind: SurveyMetaKind.deadline,
      metaText: 'Deadline: 12 hari lagi',
    ),
    SurveyEntity(
      id: 'survey-2',
      title: 'UX Testing Aplikasi Mobile',
      category: 'UX Research',
      status: SurveyStatus.paused,
      durationMinutes: 15,
      incentiveAmount: 20000,
      targetLabel: 'Pengguna Aktif Aplikasi',
      deadlineDate: DateTime(2026, 9, 25),
      respondentCount: 120,
      targetCount: 150,
      views: 198,
      conversionPercent: 31.4,
      metaKind: SurveyMetaKind.paused,
      metaText: 'Dijeda 3 hari lalu',
    ),
    SurveyEntity(
      id: 'survey-3',
      title: 'Riset Pasar FMCG Jakarta',
      category: 'Riset Pasar',
      status: SurveyStatus.open,
      durationMinutes: 8,
      incentiveAmount: 10000,
      targetLabel: 'Ibu Rumah Tangga 25-40 tahun',
      deadlineDate: DateTime(2026, 9, 13),
      respondentCount: 100,
      targetCount: 250,
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
      category: 'Brand Awareness',
      status: SurveyStatus.closed,
      durationMinutes: 12,
      incentiveAmount: 25000,
      targetLabel: 'Karyawan Kantoran 22-35 tahun',
      deadlineDate: DateTime(2026, 9, 2),
      respondentCount: 300,
      targetCount: 300,
      views: 450,
      conversionPercent: 44.4,
      metaKind: SurveyMetaKind.completed,
      metaText: 'Selesai · 6 hari lalu',
    ),
  ];

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
    return _surveys.where((survey) => survey.status != SurveyStatus.deleted).toList();
  }

  @override
  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status) async {
    await Future.delayed(_networkDelay);
    final index = _surveys.indexWhere((survey) => survey.id == surveyId);
    if (index == -1) {
      throw StateError('Survey dengan id "$surveyId" tidak ditemukan.');
    }
    final metaKind = switch (status) {
      SurveyStatus.paused => SurveyMetaKind.paused,
      SurveyStatus.open => SurveyMetaKind.resumed,
      SurveyStatus.closed => SurveyMetaKind.completed,
      SurveyStatus.deleted => _surveys[index].metaKind,
    };
    final metaText = switch (status) {
      SurveyStatus.paused => 'Dijeda baru saja',
      SurveyStatus.open => 'Dilanjutkan baru saja',
      SurveyStatus.closed => 'Selesai · baru saja',
      SurveyStatus.deleted => _surveys[index].metaText,
    };
    _surveys[index] = _surveys[index].copyWith(status: status, metaKind: metaKind, metaText: metaText);
  }

  @override
  Future<void> deleteSurvey(String surveyId) async {
    await Future.delayed(_networkDelay);
    final index = _surveys.indexWhere((survey) => survey.id == surveyId);
    if (index == -1) {
      throw StateError('Survey dengan id "$surveyId" tidak ditemukan.');
    }
    _surveys[index] = _surveys[index].copyWith(status: SurveyStatus.deleted);
  }
}
