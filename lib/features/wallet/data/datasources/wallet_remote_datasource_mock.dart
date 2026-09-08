import '../../domain/entities/transaction_entity.dart';
import 'wallet_remote_datasource.dart';

/// Data dummy — isinya PERSIS nyamain contoh di frame Figma
/// `researcher-wallet` (get_design_context, node 77:2237): saldo
/// `Rp 350.000` + 5 transaksi (2 deposit, 3 biaya survey/featured fee).
///
/// Catetan: nominal saldo `350000` di sini SAMA kayak
/// `DashboardStatsEntity.saldo` di `ResearcherRemoteDataSourceMock` — dua-
/// duanya dijaga MANUAL biar konsisten (belum ada 1 sumber kebenaran
/// beneran karena keduanya masih dummy data terpisah per fitur; nanti pas
/// backend beneran CPMK 5, wallet balance jadi satu-satunya sumber & stat
/// card dashboard tinggal fetch dari situ).
class WalletRemoteDataSourceMock implements WalletRemoteDataSource {
  const WalletRemoteDataSourceMock();

  static const _networkDelay = Duration(milliseconds: 700);

  @override
  Future<int> getBalance() async {
    await Future.delayed(_networkDelay);
    return 350000;
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    await Future.delayed(_networkDelay);
    return [
      TransactionEntity(
        id: 'trx-1',
        type: TransactionType.deposit,
        title: 'Deposit Dana',
        amount: 200000,
        date: DateTime(2026, 8, 28),
      ),
      TransactionEntity(
        id: 'trx-2',
        type: TransactionType.expense,
        title: 'Biaya Survey: Kepuasan Pelanggan',
        amount: 120000,
        date: DateTime(2026, 8, 25),
      ),
      TransactionEntity(
        id: 'trx-3',
        type: TransactionType.expense,
        title: 'Featured Survey Fee',
        amount: 5000,
        date: DateTime(2026, 8, 25),
      ),
      TransactionEntity(
        id: 'trx-4',
        type: TransactionType.deposit,
        title: 'Deposit Dana',
        amount: 500000,
        date: DateTime(2026, 8, 20),
      ),
      TransactionEntity(
        id: 'trx-5',
        type: TransactionType.expense,
        title: 'Biaya Survey: Riset Pasar FMCG',
        amount: 225000,
        date: DateTime(2026, 8, 18),
      ),
    ];
  }
}
