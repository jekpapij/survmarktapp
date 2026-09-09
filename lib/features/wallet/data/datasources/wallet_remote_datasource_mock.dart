import '../../../auth/domain/entities/user_entity.dart';
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
///
/// **Update 2026-09-09 — role-aware buat `respondent-wallet` (node
/// 77:3000):** saldo & riwayat transaksi RESPONDEN semantiknya beda TOTAL
/// dari researcher (insentif diterima + penarikan ke bank/e-wallet, BUKAN
/// deposit + biaya survey) — jadi 2 method di bawah CABANG berdasarkan
/// `forRole`. `TransactionEntity`/`TransactionType` (deposit/expense) TETAP
/// dipakai ulang PERSIS TANPA perubahan skema — `deposit` = insentif masuk
/// (ijo, +), `expense` = penarikan dana keluar (abu-abu, -), cocok pas
/// banget sama makna type yang sama dipakai researcher (deposit = uang
/// masuk, expense = uang keluar), cuma labelnya beda konteks. `forRole ==
/// null` ATAU `peneliti` -> perilaku LAMA (researcher), nggak berubah.
class WalletRemoteDataSourceMock implements WalletRemoteDataSource {
  // Update CPMK 4: BUKAN `const` lagi — saldo & daftar transaksi sekarang
  // STATEFUL (pola sama kayak `AdminRemoteDataSourceMock`), karena
  // `requestWithdrawal` beneran motong saldo & nambah baris transaksi baru
  // (dipakai pas online LANGSUNG, atau pas replay antrean offline — lihat
  // `WalletRepositoryImpl.syncPendingWithdrawals`). Instance-nya di-wiring
  // sebagai singleton lewat `Provider` biasa (bukan `autoDispose`) di
  // `wallet_providers.dart`, pola sama persis kayak `authRemoteDataSourceProvider`.
  WalletRemoteDataSourceMock()
      : _researcherTransactions = List.of(_seedResearcherTransactions),
        _respondentTransactions = List.of(_seedRespondentTransactions),
        _researcherBalance = 350000,
        _respondentBalance = 185000;

  static const _networkDelay = Duration(milliseconds: 700);

  final List<TransactionEntity> _researcherTransactions;
  final List<TransactionEntity> _respondentTransactions;
  int _researcherBalance;
  int _respondentBalance;
  int _withdrawalSeq = 0;

  @override
  Future<int> getBalance({UserRole? forRole}) async {
    await Future.delayed(_networkDelay);
    return forRole == UserRole.responden ? _respondentBalance : _researcherBalance;
  }

  @override
  Future<List<TransactionEntity>> getTransactions({UserRole? forRole}) async {
    await Future.delayed(_networkDelay);
    if (forRole == UserRole.responden) return List.unmodifiable(_respondentTransactions);
    return List.unmodifiable(_researcherTransactions);
  }

  /// CPMK 4 — simulasi "server" nerima permintaan Tarik Dana: potong saldo
  /// & catet transaksi `expense` baru (paling atas/terbaru). Nggak ada
  /// validasi saldo minimum (di luar scope demo offline-first ini) — murni
  /// buat buktiin alur baca-cache/tulis-offline/sync-online-nya jalan.
  @override
  Future<TransactionEntity> requestWithdrawal({required UserRole forRole, required int amount}) async {
    await Future.delayed(_networkDelay);
    _withdrawalSeq++;
    final tx = TransactionEntity(
      id: 'wd-sync-$_withdrawalSeq',
      type: TransactionType.expense,
      title: forRole == UserRole.responden ? 'Penarikan ke Bank (Tarik Dana)' : 'Deposit Dana',
      amount: amount,
      date: DateTime.now(),
    );
    if (forRole == UserRole.responden) {
      _respondentBalance -= amount;
      _respondentTransactions.insert(0, tx);
    } else {
      _researcherBalance -= amount;
      _researcherTransactions.insert(0, tx);
    }
    return tx;
  }

  // Update 2026-09-09 (bugfix): `static final`, BUKAN `static const` —
  // `TransactionEntity` sendiri const-constructible, tapi field `date`-nya
  // diisi `DateTime(...)`, dan `DateTime` TIDAK punya const constructor di
  // Dart. List `const` mewajibkan SEMUA elemen (termasuk argumen nested)
  // berupa compile-time constant, jadi `TransactionEntity(..., date:
  // DateTime(...))` di dalam `static const` gagal compile (const_with_non_
  // const / non_constant_list_element / const_initialized_with_non_
  // constant_value). `static final` cukup single-assignment, nggak
  // wajib compile-time-constant — lihat CLAUDE.md buat detail lengkap.
  static final _seedResearcherTransactions = [
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

  /// Update 2026-09-09: PERSIS nyamain 5 transaction-row di frame Figma
  /// `respondent-wallet` — 3x insentif (deposit) + 2x penarikan (expense),
  /// LENGKAP JAM-nya (bukan cuma tanggal kayak `_researcherTransactions`)
  /// karena Figma nunjukin timestamp "24 Agt 2026 • 14:20", bukan tanggal
  /// polos — lihat `Formatters.dateTimeShort` (nampilin jam kalau ada,
  /// nyembunyiin kalau 00:00 biar `_researcherTransactions` di atas nggak
  /// ikut kena efek nampilin "• 00:00" palsu).
  static final _seedRespondentTransactions = [
    TransactionEntity(
      id: 'rtrx-1',
      type: TransactionType.deposit,
      title: 'Insentif: Kebiasaan Belanja Online',
      amount: 15000,
      date: DateTime(2026, 8, 24, 14, 20),
    ),
    TransactionEntity(
      id: 'rtrx-2',
      type: TransactionType.deposit,
      title: 'Insentif: Kepuasan Layanan Streaming',
      amount: 25000,
      date: DateTime(2026, 8, 22, 9, 15),
    ),
    TransactionEntity(
      id: 'rtrx-3',
      type: TransactionType.expense,
      title: 'Penarikan ke Bank BCA',
      amount: 100000,
      date: DateTime(2026, 8, 20, 17, 0),
    ),
    TransactionEntity(
      id: 'rtrx-4',
      type: TransactionType.deposit,
      title: 'Insentif: Penggunaan Transportasi Umum',
      amount: 20000,
      date: DateTime(2026, 8, 18, 11, 30),
    ),
    TransactionEntity(
      id: 'rtrx-5',
      type: TransactionType.expense,
      title: 'Penarikan ke OVO',
      amount: 50000,
      date: DateTime(2026, 8, 15, 18, 45),
    ),
  ];
}
