import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheSession({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
  });

  Future<UserModel?> getCachedUser();

  /// Update 2026-09-08: overwrite CUMA bagian user di cache (bukan
  /// token) — dipakai setelah "Edit Profil" sukses, biar data yang
  /// ke-cache sinkron sama perubahan tanpa perlu login ulang / re-cache
  /// token yang nggak berubah.
  Future<void> updateCachedUser(UserModel user);

  Future<String?> getAccessToken();

  Future<void> clearSession();

  Future<String?> getLastLoginIdentifier();

  Future<void> saveLastLoginIdentifier(String identifier);
}

/// Token & user cache disimpan di Flutter Secure Storage (bukan Hive) —
/// sesuai PROMPT_SPEC.md §2.1: "Hive (cache data), Flutter Secure Storage
/// (token & sensitive)". User yang login itu sendiri termasuk data sensitif
/// ringan, jadi ikut disimpan di secure storage yang sama dengan token.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> cacheSession({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(key: StorageKeys.accessToken, value: accessToken),
        _secureStorage.write(key: StorageKeys.refreshToken, value: refreshToken),
        _secureStorage.write(key: StorageKeys.cachedUser, value: jsonEncode(user.toJson())),
      ]);
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final raw = await _secureStorage.read(key: StorageKeys.cachedUser);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<void> updateCachedUser(UserModel user) async {
    try {
      await _secureStorage.write(key: StorageKeys.cachedUser, value: jsonEncode(user.toJson()));
    } catch (_) {
      throw const CacheException();
    }
  }

  @override
  Future<String?> getAccessToken() => _secureStorage.read(key: StorageKeys.accessToken);

  @override
  Future<void> clearSession() async {
    await Future.wait([
      _secureStorage.delete(key: StorageKeys.accessToken),
      _secureStorage.delete(key: StorageKeys.refreshToken),
      _secureStorage.delete(key: StorageKeys.cachedUser),
    ]);
  }

  @override
  Future<String?> getLastLoginIdentifier() => _secureStorage.read(key: StorageKeys.lastLoginIdentifier);

  @override
  Future<void> saveLastLoginIdentifier(String identifier) =>
      _secureStorage.write(key: StorageKeys.lastLoginIdentifier, value: identifier);
}
