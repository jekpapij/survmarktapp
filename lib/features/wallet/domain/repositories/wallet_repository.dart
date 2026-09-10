import '../../../auth/domain/entities/user_entity.dart';
import '../entities/transaction_entity.dart';

/// Kontrak layer domain buat fitur wallet — pola sama persis kayak
/// `ResearcherRepository`/`NotificationRepository`.
///
/// Update 2026-09-09: `forRole` opsional ditambahin buat `respondent-wallet`
/// (get_design_context node 77:3000) — saldo & isi riwayat transaksi
/// respondent SEMANTIKNYA beda total dari researcher (insentif diterima +
/// penarikan ke bank/e-wallet, BUKAN deposit + biaya survey), jadi mock-nya
/// perlu tau lagi ROLE siapa yang minta. `TransactionEntity`/`TransactionType`
/// (deposit/expense) TETAP dipakai ulang PERSIS sama tanpa perubahan — cuma
/// datanya yang beda per role, sesuai rencana reuse yang udah dicatet dari
/// awal di situ. Default `null`/`UserRole.peneliti` -> data researcher
/// (perilaku LAMA, backward-compatible, nggak ngubah apapun buat wallet
/// researcher yang udah jalan).
abstract class WalletRepository {
  Future<int> getBalance({UserRole? forRole});

  Future<List<TransactionEntity>> getTransactions({UserRole? forRole});

  // Update CPMK 4 (Persistent Data & Offline-First) — 2 method baru di
  // bawah nge-implementasikan Panduan Pengerjaan poin 2 ("Aplikasi tetap
  // dapat membaca dan menulis data transaksi/aktivitas saat offline, lalu
  // disinkronkan ketika koneksi internet kembali"), khusus buat data
  // Wallet (scope yang dipilih buat CPMK 4 ini — bukan semua fitur
  // sekaligus, lihat CLAUDE.md).

  /// Tarik Dana (respondent) / Deposit Dana (researcher). Kalau device
  /// ONLINE: langsung diproses ke `WalletRemoteDataSource` + cache
  /// di-update. Kalau OFFLINE: transaksi optimis (`isPendingSync: true`)
  /// langsung kebentuk & disimpan lokal (Hive), TANPA nunggu/gagal —
  /// nanti di-replay beneran ke datasource pas `syncPendingTransactions`
  /// jalan (otomatis pas koneksi balik, lihat `wallet_providers.dart`).
  Future<TransactionEntity> requestWithdrawal({required UserRole forRole, required int amount});

  /// Replay semua transaksi yang ke-antre pas offline ke
  /// `WalletRemoteDataSource` yang SEBENARNYA, lalu kosongin antrean &
  /// refresh cache. No-op (balikin 0) kalau nggak ada yang diantre atau
  /// device masih offline.
  Future<int> syncPendingTransactions({required UserRole? forRole});
}
