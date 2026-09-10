import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_retry.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import 'wallet_remote_datasource.dart';

/// CPMK 5 (Integration Engine) — implementasi BENERAN dari
/// [WalletRemoteDataSource], backend-nya Firestore (`ApiConstants.
/// useFirebaseBackend`, scope "Auth + Wallet dulu"). GANTIIN
/// [WalletRemoteDataSourceMock] doang — [WalletRepositoryImpl] (orkestrator
/// offline-first CPMK 4: baca-cache/tulis-offline/sync-online) **SAMA
/// SEKALI NGGAK BERUBAH**, cuma remote datasource-nya yang di-swap lewat
/// `wallet_providers.dart`, persis manfaat Clean Architecture yang sama
/// kayak swap Mock<->Firebase di Auth.
///
/// Skema Firestore: `wallets/{uid}` (field `balance`, int) + subcollection
/// `wallets/{uid}/transactions/{txId}` (field `type`/`title`/`amount`/
/// `status`/`createdAt`). Dokumen `wallets/{uid}` awal (`balance: 0`) udah
/// dibikin bareng `users/{uid}` pas register/Google registration selesai
/// (lihat `AuthRemoteDataSourceFirebase._createUserDocuments`) — kalau
/// somehow belum ada (mis. akun lama dari sebelum CPMK 5), [getBalance]
/// fallback ke `0`, BUKAN error.
///
/// **Transaksi `status: 'pending'` (dari alur Deposit Dana via Midtrans,
/// lihat `MidtransService`) SENGAJA DIFILTER KELUAR dari [getTransactions]**
/// — beda konsep dari `isPendingSync` CPMK 4 (transaksi offline yang BELUM
/// ke-replay ke server): ini transaksi yang UDAH nyampe server tapi
/// pembayarannya sendiri belum dikonfirmasi Midtrans. UX "menunggu
/// pembayaran"-nya ditangani PENUH oleh dialog `_WaitingPaymentDialog` di
/// `researcher_wallet_screen.dart` (listen live ke 1 dokumen transaksi
/// spesifik), BUKAN nampilin baris "pending" campur aduk di riwayat sini —
/// biar nggak nabrak makna `isPendingSync` yang udah ada & udah
/// dikonfirmasi kerja bener di CPMK 4.
class WalletRemoteDataSourceFirestore implements WalletRemoteDataSource {
  WalletRemoteDataSourceFirestore({fb.FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _wallets => _firestore.collection('wallets');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan login ulang.');
    }
    return uid;
  }

  @override
  Future<int> getBalance({UserRole? forRole}) async {
    final uid = _requireUid();
    try {
      final doc = await withNetworkRetry(() => _wallets.doc(uid).get());
      return (doc.data()?['balance'] as num?)?.toInt() ?? 0;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions({UserRole? forRole}) async {
    final uid = _requireUid();
    try {
      final snapshot = await withNetworkRetry(
        () => _wallets.doc(uid).collection('transactions').orderBy('createdAt', descending: true).limit(50).get(),
      );
      return snapshot.docs
          .where((doc) => (doc.data()['status'] as String? ?? 'success') == 'success')
          .map(_transactionFromDoc)
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  TransactionEntity _transactionFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TransactionEntity(
      id: doc.id,
      type: TransactionType.values.firstWhere(
        (t) => t.name == data['type'] as String?,
        orElse: () => TransactionType.expense,
      ),
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Dipanggil pas ONLINE — [WalletRepositoryImpl] yang urus antrean
  /// offline (Hive), di sini cuma perlu jamin `balance` & baris transaksi
  /// baru KONSISTEN pakai 1 Firestore transaction (atomik), biar nggak ada
  /// race condition kalau kebetulan ada 2 penarikan diproses hampir
  /// bersamaan (jarang buat demo, tapi ini praktik yang bener).
  @override
  Future<TransactionEntity> requestWithdrawal({required UserRole forRole, required int amount}) async {
    final uid = _requireUid();
    try {
      return await withNetworkRetry(() => _firestore.runTransaction<TransactionEntity>((txn) async {
            final walletRef = _wallets.doc(uid);
            final snapshot = await txn.get(walletRef);
            final currentBalance = (snapshot.data()?['balance'] as num?)?.toInt() ?? 0;
            final txRef = walletRef.collection('transactions').doc();
            final entity = TransactionEntity(
              id: txRef.id,
              type: TransactionType.expense,
              title: forRole == UserRole.responden ? 'Penarikan ke Bank (Tarik Dana)' : 'Deposit Dana',
              amount: amount,
              date: DateTime.now(),
            );
            txn.set(txRef, {
              'type': entity.type.name,
              'title': entity.title,
              'amount': entity.amount,
              'status': 'success',
              'createdAt': FieldValue.serverTimestamp(),
            });
            txn.set(walletRef, {'balance': currentBalance - amount}, SetOptions(merge: true));
            return entity;
          }));
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Exception _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return const NetworkException('Koneksi ke server bermasalah. Coba lagi.');
      case 'permission-denied':
        return const ServerException('Akses ditolak — cek Firestore Security Rules.');
      default:
        return ServerException(e.message ?? 'Terjadi kesalahan Firestore.');
    }
  }
}
