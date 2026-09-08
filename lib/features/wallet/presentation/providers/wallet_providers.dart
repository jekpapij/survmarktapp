import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final walletProvider = FutureProvider<WalletData>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  final results = await Future.wait([
    repository.getBalance(),
    repository.getTransactions(),
  ]);
  return WalletData(
    balance: results[0] as int,
    transactions: results[1] as List<TransactionEntity>,
  );
});
