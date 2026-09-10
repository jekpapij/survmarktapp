import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../models/transaction_model.dart';

/// CPMK 4 (Persistent Data & Offline-First) — cache lokal buat data Wallet,
/// pakai **Hive** (`Box<String>`, isinya JSON — bukan `@HiveType` codegen,
/// lihat catatan lengkap di `main.dart` kenapa). Wallet dipilih sebagai
/// modul PERTAMA yang dikasih local-cache+offline-first beneran (bukan
/// semua fitur sekaligus) — representatif buat kata "transaksi/aktivitas"
/// di Panduan Pengerjaan CPMK 4, dan datanya paling kritikal buat tetap bisa
/// dibaca walau device lagi offline (saldo/riwayat transaksi, bukan sekadar
/// listing yang bisa nunggu refresh).
abstract class WalletLocalDataSource {
  Future<void> cacheBalance({required UserRole? forRole, required int balance});

  Future<int?> getCachedBalance({required UserRole? forRole});

  Future<void> cacheTransactions({required UserRole? forRole, required List<TransactionModel> transactions});

  Future<List<TransactionModel>?> getCachedTransactions({required UserRole? forRole});

  /// Antrean tulis OFFLINE — "Tarik Dana" yang dibuat saat device nggak
  /// ada koneksi masuk sini dulu (BUKAN langsung ke `WalletRemoteDataSource`
  /// yang butuh "server"), ditandai `isPendingSync: true`. `forRole`
  /// eksplisit (bukan ditebak dari `pending.id`) biar nggak fragile.
  Future<void> queuePendingWithdrawal({required UserRole? forRole, required TransactionModel pending});

  Future<List<TransactionModel>> getPendingWithdrawals({required UserRole? forRole});

  Future<void> clearPendingWithdrawals({required UserRole? forRole});
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  WalletLocalDataSourceImpl();

  static const _boxName = 'wallet_cache';

  // Bugfix (laporan user — `flutter run` gagal build): versi ternary
  // sebelumnya (`cond ? Hive.box<String>(...) : Hive.openBox<String>(...)`)
  // GAGAL compile — cabang `Hive.box<String>(...)` sinkron (`Box<String>`)
  // sementara cabang `Hive.openBox<String>(...)` async (`Future<Box<
  // String>>`), Dart nggak bisa nyatuin tipe ternary itu (ke-infer jadi
  // `Object`, nggak valid buat balikin dari fungsi `async` yang declared
  // `Future<Box<String>>`). Fix: pisah jadi `if`/`return` biasa — tiap
  // `return` di fungsi `async` di-wrap `Future` SENDIRI-SENDIRI sama
  // compiler, jadi cabang sinkron (`Hive.box`) & cabang `Future`
  // (`Hive.openBox`) dua-duanya valid tanpa perlu disamain tipe manual.
  Future<Box<String>> get _box async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return Hive.openBox<String>(_boxName);
  }

  /// `forRole == null` disamain sama `UserRole.peneliti` — konsisten sama
  /// perilaku default lama di `WalletRemoteDataSourceMock`/`WalletRepository`
  /// ("`forRole` null atau peneliti -> data researcher").
  String _roleSlug(UserRole? forRole) => (forRole ?? UserRole.peneliti).name;

  @override
  Future<void> cacheBalance({required UserRole? forRole, required int balance}) async {
    try {
      final box = await _box;
      await box.put('balance_${_roleSlug(forRole)}', balance.toString());
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<int?> getCachedBalance({required UserRole? forRole}) async {
    try {
      final box = await _box;
      final raw = box.get('balance_${_roleSlug(forRole)}');
      return raw == null ? null : int.tryParse(raw);
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheTransactions({
    required UserRole? forRole,
    required List<TransactionModel> transactions,
  }) async {
    try {
      final box = await _box;
      final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
      await box.put('transactions_${_roleSlug(forRole)}', encoded);
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<List<TransactionModel>?> getCachedTransactions({required UserRole? forRole}) async {
    try {
      final box = await _box;
      final raw = box.get('transactions_${_roleSlug(forRole)}');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> queuePendingWithdrawal({required UserRole? forRole, required TransactionModel pending}) async {
    try {
      final box = await _box;
      // `pending.isPendingSync` dipastikan `true` udah dari caller
      // (`WalletRepositoryImpl`), bukan tanggung jawab datasource ini.
      // Role ditulis manual sebagai tag terpisah di JSON (bukan lewat
      // `_roleSlug` sebagai bagian KEY Hive) karena antrean `pending_<id>`
      // sengaja 1 namespace global (nggak perlu kepisah kayak
      // balance/transactions) — role tetap perlu disimpen biar
      // `getPendingWithdrawals`/sync tau ini punya siapa.
      final key = 'pending_${pending.id}';
      await box.put(key, jsonEncode({...pending.toJson(), '_role': _roleSlug(forRole)}));
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<List<TransactionModel>> getPendingWithdrawals({required UserRole? forRole}) async {
    try {
      final box = await _box;
      final roleSlug = _roleSlug(forRole);
      final result = <TransactionModel>[];
      for (final key in box.keys.where((k) => (k as String).startsWith('pending_'))) {
        final raw = box.get(key);
        if (raw == null) continue;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json['_role'] != roleSlug) continue;
        result.add(TransactionModel.fromJson(json));
      }
      result.sort((a, b) => a.date.compareTo(b.date));
      return result;
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> clearPendingWithdrawals({required UserRole? forRole}) async {
    try {
      final box = await _box;
      final roleSlug = _roleSlug(forRole);
      final keysToRemove = <dynamic>[];
      for (final key in box.keys.where((k) => (k as String).startsWith('pending_'))) {
        final raw = box.get(key);
        if (raw == null) continue;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json['_role'] == roleSlug) keysToRemove.add(key);
      }
      await box.deleteAll(keysToRemove);
    } catch (_) {
      throw const CacheException();
    }
  }
}
