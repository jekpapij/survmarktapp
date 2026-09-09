import '../../domain/entities/respondent_activity_entity.dart';
import '../../domain/entities/survey_listing_entity.dart';
import 'respondent_remote_datasource.dart';

/// Data dummy — isinya PERSIS nyamain 5 contoh survei di frame Figma
/// `respondent-discover` (get_design_context, node 77:2719): 1 featured
/// ("Studi Adopsi Teknologi AI di UMKM") + 4 survei biasa. Pola sama kayak
/// `ResearcherRemoteDataSourceMock`/`AuthRemoteDataSourceMock` — delay
/// buatan biar state Loading beneran kebukti jalan (CPMK 3), scope mock
/// semua fitur baru per keputusan user 2026-09-08.
///
/// Kategori (`pendidikan`/`kesehatan`/`bisnis`) di-infer manual dari
/// konteks judul/institusi tiap survei (Figma cuma nunjukin 4 filter chip
/// contoh, nggak nge-tag kategori eksplisit per card) — lihat catatan di
/// `SurveyCategory`.
///
/// **Update 2026-09-09 — jadi STATEFUL (bukan `const` lagi):** buat nampung
/// `_activities` yang bisa BERTAMBAH pas user tap "Isi Survei" di
/// `SurveyDetailModal` (`submitSurveyResponse`). Diterapin dari AWAL kali
/// ini (bukan nunggu laporan bug) — pelajaran langsung dari bugfix
/// `AuthRemoteDataSourceMock` sebelumnya (Update 2026-09-09 "register+login
/// sebagai Responden malah ke-routing ke Researcher"): data yang "dipilih/
/// dihasilkan user sendiri" (bukan cuma ditebak dari teks) WAJIB kesimpen di
/// state kelas, jangan cuma numpang lewat.
class RespondentRemoteDataSourceMock implements RespondentRemoteDataSource {
  RespondentRemoteDataSourceMock();

  static const _networkDelay = Duration(milliseconds: 700);

  static const _surveys = [
    SurveyListingEntity(
      id: 'discover-1',
      title: 'Studi Adopsi Teknologi AI di UMKM',
      authorLabel: 'Dr. Rina Hartono • Universitas Indonesia',
      category: SurveyCategory.pendidikan,
      incentiveAmount: 25000,
      durationMinutes: 20,
      respondentCount: 12,
      targetCount: 80,
      daysLeft: 30,
      featured: true,
    ),
    SurveyListingEntity(
      id: 'discover-2',
      title: 'Survei Kebiasaan Belanja Online Gen Z',
      authorLabel: 'Tim Riset Tokopedia',
      category: SurveyCategory.bisnis,
      incentiveAmount: 15000,
      durationMinutes: 15,
      respondentCount: 45,
      targetCount: 100,
      daysLeft: 14,
      badge: SurveyListingBadge.matched,
    ),
    SurveyListingEntity(
      id: 'discover-3',
      title: 'Evaluasi Layanan Kesehatan Digital',
      authorLabel: 'Kemenkes RI',
      category: SurveyCategory.kesehatan,
      incentiveAmount: 20000,
      durationMinutes: 25,
      respondentCount: 8,
      targetCount: 50,
      daysLeft: 21,
    ),
    SurveyListingEntity(
      id: 'discover-4',
      title: 'Persepsi Masyarakat terhadap Energi Terbarukan',
      authorLabel: 'PLN Research Institute',
      category: SurveyCategory.bisnis,
      incentiveAmount: 10000,
      durationMinutes: 10,
      respondentCount: 72,
      targetCount: 80,
      daysLeft: 2,
      badge: SurveyListingBadge.expiringSoon,
    ),
    SurveyListingEntity(
      id: 'discover-5',
      title: 'Studi Pola Mobilitas Urban Jabodetabek',
      authorLabel: 'Bappenas • Kementerian PPN',
      category: SurveyCategory.pendidikan,
      incentiveAmount: 30000,
      durationMinutes: 30,
      respondentCount: 5,
      targetCount: 60,
      daysLeft: 25,
      badge: SurveyListingBadge.matched,
    ),
  ];

  @override
  Future<List<SurveyListingEntity>> getDiscoverSurveys() async {
    await Future.delayed(_networkDelay);
    return _surveys;
  }

  /// Seed PERSIS nyamain 5 contoh kartu di frame Figma `respondent-activity`
  /// (get_design_context, node 77:2902) — 3x "Menunggu Verifikasi", 1x
  /// "Diverifikasi", 1x "Ditolak". Bukan `static const` (beda dari
  /// `_surveys`) karena list ini BERTAMBAH lewat `submitSurveyResponse`.
  final List<RespondentActivityEntity> _activities = [
    RespondentActivityEntity(
      id: 'activity-1',
      surveyTitle: 'Studi Adopsi Teknologi AI di UMKM',
      status: ActivityStatus.menungguVerifikasi,
      submittedAt: DateTime(2026, 8, 28),
      incentiveAmount: 25000,
    ),
    RespondentActivityEntity(
      id: 'activity-2',
      surveyTitle: 'Survei Kebiasaan Belanja Online Gen Z',
      status: ActivityStatus.diverifikasi,
      submittedAt: DateTime(2026, 8, 25),
      incentiveAmount: 15000,
    ),
    RespondentActivityEntity(
      id: 'activity-3',
      surveyTitle: 'Evaluasi Layanan Kesehatan Digital',
      status: ActivityStatus.menungguVerifikasi,
      submittedAt: DateTime(2026, 8, 24),
      incentiveAmount: 20000,
    ),
    RespondentActivityEntity(
      id: 'activity-4',
      surveyTitle: 'Persepsi Energi Terbarukan di Kalangan Milenial',
      status: ActivityStatus.ditolak,
      submittedAt: DateTime(2026, 8, 20),
      incentiveAmount: 10000,
    ),
    RespondentActivityEntity(
      id: 'activity-5',
      surveyTitle: 'Pola Mobilitas Urban Jabodetabek',
      status: ActivityStatus.menungguVerifikasi,
      submittedAt: DateTime(2026, 8, 18),
      incentiveAmount: 30000,
    ),
  ];

  @override
  Future<List<RespondentActivityEntity>> getActivities() async {
    await Future.delayed(_networkDelay);
    // List baru (bukan referensi mentah `_activities`) — jaga-jaga biar
    // caller nggak bisa nyelundup mutasi langsung ke state internal mock,
    // pola sama kayak `ResearcherRemoteDataSourceMock`.
    return List.unmodifiable(_activities.reversed);
  }

  @override
  Future<void> submitSurveyResponse(SurveyListingEntity survey) async {
    await Future.delayed(_networkDelay);
    _activities.add(
      RespondentActivityEntity(
        id: 'activity-${DateTime.now().millisecondsSinceEpoch}',
        surveyTitle: survey.title,
        status: ActivityStatus.menungguVerifikasi,
        submittedAt: DateTime.now(),
        incentiveAmount: survey.incentiveAmount,
      ),
    );
  }
}
