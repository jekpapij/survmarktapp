import '../../../../core/network/connectivity_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../models/transaction_model.dart';

/// CPMK 4 (Persistent Data & Offline-First) — di sinilah pola
/// "baca-cache-dulu/tulis-offline/sync-pas-online" beneran di-orkestrasi
/// (bukan di datasource ataupun UI). Sebelum CPMK 4, kelas ini cuma
/// passthrough tipis 2 baris ke `WalletRemoteDataSource` — sekarang jadi
/// SATU-SATUNYA tempat yang tau soal `ConnectivityService` +
/// `WalletLocalDataSource` sekaligus, persis manfaat Clean Architecture
/// yang disebut CLAUDE.md berkali-kali: datasource & UI di atasnya nggak
/// perlu tau apa-apa soal online/offline sama sekali.
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl({
    required WalletRemoteDataSource remoteDataSource,
    required WalletLocalDataSource localDataSource,
    required ConnectivityService connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity;

  final WalletRemoteDataSource _remoteDataSource;
  final WalletLocalDataSource _localDataSource;
  final ConnectivityService _connectivity;

  @override
  Future<int> getBalance({UserRole? forRole}) async {
    final isOnline = await _connectivity.isOnline();
    int balance;
    if (isOnline) {
      balance = await _remoteDataSource.getBalance(forRole: forRole);
      await _localDataSource.cacheBalance(forRole: forRole, balance: balance);
    } else {
      final cached = await _localDataSource.getCachedBalance(forRole: forRole);
      // Belum PERNAH online sama sekali (cache kosong) — nggak ada apa-apa
      // buat ditampilin, 0 sebagai fallback paling aman (bukan nge-throw
      // dan bikin seluruh `walletProvider` gagal cuma gara-gara ini).
      balance = cached ?? 0;
    }
    // Saldo yang ketampil harus udah nyerminin penarikan yang masih
    // ke-antre offline (belum ke-ACC "server") — dipotong optimis di sini,
    // BUKAN disimpen dobel sebagai angka statis terpisah (prinsip "1
    // sumber kebenaran" yang sama dipakein di banner completion %/wallet
    // dashboard sepanjang proyek ini).
    final pending = await _localDataSource.getPendingWithdrawals(forRole: forRole);
    final pendingTotal = pending.fold<int>(0, (sum, t) => sum + t.amount);
    return balance - pendingTotal;
  }

  @override
  Future<List<TransactionEntity>> getTransactions({UserRole? forRole}) async {
    final isOnline = await _connectivity.isOnline();
    List<TransactionModel> settled;
    if (isOnline) {
      final remote = await _remoteDataSource.getTransactions(forRole: forRole);
      settled = remote.map(TransactionModel.fromEntity).toList();
      await _localDataSource.cacheTransactions(forRole: forRole, transactions: settled);
    } else {
      settled = await _localDataSource.getCachedTransactions(forRole: forRole) ?? const [];
    }
    final pending = await _localDataSource.getPendingWithdrawals(forRole: forRole);
    // Antrean offline ditaro PALING ATAS (belakangan = terbaru), badge
    // "Menunggu Sinkronisasi" (`isPendingSync`) dibaca `TransactionTile`.
    return [...pending, ...settled];
  }

  @override
  Future<TransactionEntity> requestWithdrawal({required UserRole forRole, required int amount}) async {
    final isOnline = await _connectivity.isOnline();
    if (isOnline) {
      final tx = await _remoteDataSource.requestWithdrawal(forRole: forRole, amount: amount);
      // Write-through: sinkronin cache biar konsisten sama saldo/riwayat
      // "server" yang baru aja berubah, tanpa nunggu fetch berikutnya.
      final freshBalance = await _remoteDataSource.getBalance(forRole: forRole);
      final freshTransactions = await _remoteDataSource.getTransactions(forRole: forRole);
      await _localDataSource.cacheBalance(forRole: forRole, balance: freshBalance);
      await _localDataSource.cacheTransactions(
        forRole: forRole,
        transactions: freshTransactions.map(TransactionModel.fromEntity).toList(),
      );
      return tx;
    }

    // OFFLINE — jangan gagal, jangan nunggu. Bikin transaksi optimis lokal
    // + masukin antrean, biar user tetap "bisa nulis" walau nggak ada
    // internet (Panduan Pengerjaan CPMK 4 poin 2, literal).
    final pending = TransactionModel(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      type: TransactionType.expense,
      title: forRole == UserRole.responden ? 'Penarikan ke Bank (Tarik Dana)' : 'Deposit Dana',
      amount: amount,
      date: DateTime.now(),
      isPendingSync: true,
    );
    await _localDataSource.queuePendingWithdrawal(forRole: forRole, pending: pending);
    return pending;
  }

  @override
  Future<int> syncPendingTransactions({required UserRole? forRole}) async {
    final isOnline = await _connectivity.isOnline();
    if (!isOnline) return 0;

    final pending = await _localDataSource.getPendingWithdrawals(forRole: forRole);
    if (pending.isEmpty) return 0;

    // Replay satu-satu, URUT (`getPendingWithdrawals` udah sort by date) —
    // biar saldo "server" kepotong dalam urutan yang bener kalau ada lebih
    // dari 1 penarikan ke-antre.
    for (final tx in pending) {
      await _remoteDataSource.requestWithdrawal(forRole: forRole ?? UserRole.peneliti, amount: tx.amount);
    }
    await _localDataSource.clearPendingWithdrawals(forRole: forRole);

    // Refresh cache dari "server" biar transaksi yang barusan di-replay
    // (dengan id resmi `wd-sync-N`, bukan `pending-*` sementara) ke-cache
    // dengan benar & nggak dobel sama versi pending-nya yang udah dihapus.
    final freshBalance = await _remoteDataSource.getBalance(forRole: forRole);
    final freshTransactions = await _remoteDataSource.getTransactions(forRole: forRole);
    await _localDataSource.cacheBalance(forRole: forRole, balance: freshBalance);
    await _localDataSource.cacheTransactions(
      forRole: forRole,
      transactions: freshTransactions.map(TransactionModel.fromEntity).toList(),
    );
    return pending.length;
  }
}
