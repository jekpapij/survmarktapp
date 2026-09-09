import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/datasources/wallet_remote_datasource_mock.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Belum ada cabang Dio beneran (nyusul CPMK 5, payment gateway) — sama
/// kayak `researcherRemoteDataSourceProvider`/`notificationRemoteDataSourceProvider`.
final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return const WalletRemoteDataSourceMock();
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteDataSourceProvider));
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
