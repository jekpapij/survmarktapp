import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/respondent_remote_datasource.dart';
import '../../data/datasources/respondent_remote_datasource_mock.dart';
import '../../data/repositories/respondent_repository_impl.dart';
import '../../domain/entities/survey_listing_entity.dart';
import '../../domain/repositories/respondent_repository.dart';

/// Belum ada cabang Dio beneran (nyusul CPMK 5) — sama kayak
/// `researcherRemoteDataSourceProvider`, jadi belum dipasang toggle
/// `ApiConstants.useMockBackend`.
final respondentRemoteDataSourceProvider = Provider<RespondentRemoteDataSource>((ref) {
  return const RespondentRemoteDataSourceMock();
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
