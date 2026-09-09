import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/respondent_remote_datasource.dart';
import '../../data/datasources/respondent_remote_datasource_mock.dart';
import '../../data/repositories/respondent_repository_impl.dart';
import '../../domain/entities/respondent_activity_entity.dart';
import '../../domain/entities/survey_listing_entity.dart';
import '../../domain/repositories/respondent_repository.dart';

/// Belum ada cabang Dio beneran (nyusul CPMK 5) — sama kayak
/// `researcherRemoteDataSourceProvider`, jadi belum dipasang toggle
/// `ApiConstants.useMockBackend`.
///
/// Update 2026-09-09: `RespondentRemoteDataSourceMock` bukan `const` lagi
/// (butuh state `_activities` yang bisa nambah) — `Provider` (BUKAN
/// `autoDispose`) di bawah ini otomatis bikin instance-nya singleton
/// sepanjang app jalan, pola sama kayak `authRemoteDataSourceProvider`
/// (lihat catatan di situ soal bugfix role responden 2026-09-09).
final respondentRemoteDataSourceProvider = Provider<RespondentRemoteDataSource>((ref) {
  return RespondentRemoteDataSourceMock();
});

final respondentRepositoryProvider = Provider<RespondentRepository>((ref) {
  return RespondentRepositoryImpl(ref.watch(respondentRemoteDataSourceProvider));
});

/// `FutureProvider` — `AsyncValue.when` di screen nanganin Loading/Error/
/// Success (CPMK 3), pola sama kayak `researcherDashboardProvider`/
/// `notificationsProvider`. Search & filter kategori ditanganin di CLIENT
/// (local state `RespondentDiscoverScreen`), bukan di provider ini — biar
/// provider tetap murni "fetch data", nggak perlu di-invalidate/refetch
/// tiap user ngetik atau ganti chip.
final respondentDiscoverProvider = FutureProvider<List<SurveyListingEntity>>((ref) async {
  return ref.watch(respondentRepositoryProvider).getDiscoverSurveys();
});

/// Update 2026-09-09: daftar aktivitas buat `respondent-activity` (node
/// 77:2902) — tab Aktif/Riwayat DIFILTER DI CLIENT dari 1 list ini (lihat
/// `RespondentActivityScreen`). Di-`invalidate` dari `SurveyDetailModal`
/// abis `submitSurveyResponse` berhasil, biar aktivitas baru langsung
/// kebukti tanpa keluar-masuk layar.
final respondentActivitiesProvider = FutureProvider<List<RespondentActivityEntity>>((ref) async {
  return ref.watch(respondentRepositoryProvider).getActivities();
});
