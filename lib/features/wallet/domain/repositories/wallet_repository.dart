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
}
