import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/transaction_entity.dart';

/// Kontrak data source — nanti pas CPMK 5 (Integration Engine) diimplementasi
/// beneran (payment gateway Midtrans/Xendit/Stripe sandbox buat Deposit
/// Dana beneran, bukan cuma catetan transaksi). Baru ada
/// [WalletRemoteDataSourceMock] buat sekarang.
abstract class WalletRemoteDataSource {
  Future<int> getBalance({UserRole? forRole});

  Future<List<TransactionEntity>> getTransactions({UserRole? forRole});

  /// CPMK 4 — dipanggil pas ONLINE (langsung, atau pas replay antrean
  /// offline). "Server" (mock) nyatetin transaksi baru & motong saldo,
  /// balikin `TransactionEntity` final (id resmi dari "server", bukan id
  /// sementara `pending-*` yang dipakai pas offline).
  Future<TransactionEntity> requestWithdrawal({required UserRole forRole, required int amount});
}
