import '../../domain/entities/transaction_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 (Integration Engine) diimplementasi
/// beneran (payment gateway Midtrans/Xendit/Stripe sandbox buat Deposit
/// Dana beneran, bukan cuma catetan transaksi). Baru ada
/// [WalletRemoteDataSourceMock] buat sekarang.
abstract class WalletRemoteDataSource {
  Future<int> getBalance();

  Future<List<TransactionEntity>> getTransactions();
}
