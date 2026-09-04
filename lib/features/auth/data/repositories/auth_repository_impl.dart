import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.login(identifier: identifier, password: password);
      await _localDataSource.cacheSession(
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      // Buat varian "Selamat Datang Kembali" di login berikutnya —
      // disimpan terpisah dari sesi karena tetap berguna walau nanti logout.
      await _localDataSource.saveLastLoginIdentifier(identifier);
      return Right(session.user);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role.apiValue,
      );
      // Register cuma balikin data user (bukan token — lihat PROMPT_SPEC.md
      // §8), jadi sengaja nggak di-cache sebagai sesi aktif. User tetap
      // harus login manual setelah daftar, sesuai alur di Figma
      // (register-page -> "Daftar" -> balik ke login).
      return Right(user);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Tetap lanjut clear sesi lokal walau call logout ke server gagal
      // (misal token udah expired duluan) — user harus tetap bisa "keluar".
    } finally {
      await _localDataSource.clearSession();
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final token = await _localDataSource.getAccessToken();
      if (token == null) return const Right(null);
      final user = await _localDataSource.getCachedUser();
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
