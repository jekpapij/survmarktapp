import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/wallet_local_datasource.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/datasources/wallet_remote_datasource_mock.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Update CPMK 4: BUKAN `const WalletRemoteDataSourceMock()` lagi — sekarang
/// stateful (lihat catatan lengkap di kelasnya), jadi harus `Provider`
/// biasa (singleton sepanjang app jalan, pola sama kayak
/// `authRemoteDataSourceProvider`), bukan literal const.
final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSourceMock();
});

final walletLocalDataSourceProvider = Provider<WalletLocalDataSource>((ref) {
  return WalletLocalDataSourceImpl();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  // Bugfix (laporan user — `flutter run` gagal build): `Connectivity()`
  // BUKAN const constructor (plugin class, nyiapin platform channel di
  // baliknya) — `const ConnectivityService(Connectivity())` gagal compile
  // ("Cannot invoke a non-'const' factory where a const expression is
  // expected"), walaupun `ConnectivityService` sendiri PUNYA const
  // constructor (boleh dideklarasiin const, tapi CALLER nggak wajib
  // manggil pakai `const` — di sini emang nggak bisa karena argumennya
  // bukan compile-time constant).
  return ConnectivityService(Connectivity());
});

/// Stream `true`/`false` — dipakai `walletAutoSyncProvider` buat tau kapan
/// koneksi BALIK (bukan cuma kapan device offline).
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onStatusChanged;
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    remoteDataSource: ref.watch(walletRemoteDataSourceProvider),
    localDataSource: ref.watch(walletLocalDataSourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

/// Gabungan saldo + riwayat transaksi dalam 1 fetch — pola sama kayak
/// `ResearcherDashboardData`/`researcherDashboardProvider`.
class WalletData {
  const WalletData({required this.balance, required this.transactions});

  final int balance;
  final List<TransactionEntity> transactions;
}

/// Update 2026-09-09: `forRole` diambil LIVE dari `authNotifierProvider`
/// (user yang lagi login) — bukan parameter yang di-pass manual dari
/// screen, biar `ResearcherWalletScreen`/`RespondentWalletScreen` dua-duanya
/// bisa `ref.watch(walletProvider)` polos tanpa masing-masing perlu tau soal
/// role, providernya sendiri yang otomatis nyaring data yang bener sesuai
/// siapa yang lagi login (lihat catatan lengkap di `WalletRepository`).
///
/// Update CPMK 4: sekarang lewat `WalletRepositoryImpl` yang offline-first
/// (baca cache kalau offline, gabung antrean pending) — `walletProvider`
/// SENDIRI nggak berubah sama sekali, cuma manggil method repository yang
/// sama seperti sebelumnya. Bukti konkret manfaat Clean Architecture:
/// seluruh logika online/offline nggak nyentuh layer presentation ini.
final walletProvider = FutureProvider<WalletData>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  final role = ref.watch(authNotifierProvider).user?.role;
  final results = await Future.wait([
    repository.getBalance(forRole: role),
    repository.getTransactions(forRole: role),
  ]);
  return WalletData(
    balance: results[0] as int,
    transactions: results[1] as List<TransactionEntity>,
  );
});

/// CPMK 4 — sinkronisasi OTOMATIS pas koneksi balik online (rubrik "Sangat
/// Baik": "mampu melakukan sinkronisasi otomatis saat online"), BUKAN
/// cuma manual pull-to-refresh. `ref.watch` provider ini dari
/// `RespondentWalletScreen`/`ResearcherWalletScreen` buat "nyalain"
/// listener-nya selama layar itu mounted — begitu `connectivityStatusProvider`
/// pindah dari offline ke online, antrean `pending-*` di-replay ke
/// "server" & `walletProvider` di-invalidate biar UI ke-refresh nampilin
/// hasil sync-nya (id `wd-sync-N` beneran, badge "Menunggu Sinkronisasi"
/// hilang).
final walletAutoSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) async {
    final wasOffline = previous?.valueOrNull == false;
    final nowOnline = next.valueOrNull == true;
    if (!(wasOffline && nowOnline)) return;
    final role = ref.read(authNotifierProvider).user?.role;
    final synced = await ref.read(walletRepositoryProvider).syncPendingTransactions(forRole: role);
    if (synced > 0) ref.invalidate(walletProvider);
  });
});
