import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

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

  // Update 2026-09-08: "Ubah Password"/"Lupa Password" self-designed —
  // lihat catatan lengkap di `AuthRepository`. Pola try/catch-mapping-ke-
  // Failure di bawah PERSIS sama kayak `login`/`register` di atas.

  @override
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(oldPassword: oldPassword, newPassword: newPassword);
      return const Right(null);
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
  Future<Either<Failure, void>> requestPasswordReset({required String identifier}) async {
    try {
      await _remoteDataSource.requestPasswordReset(identifier: identifier);
      return const Right(null);
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
  Future<Either<Failure, void>> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(identifier: identifier, newPassword: newPassword);
      return const Right(null);
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

  // Update 2026-09-08: "Edit Profil" self-designed — lihat catatan
  // lengkap di `AuthRepository`.
  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String name,
    required String phone,
    String institution = '',
    String academicRole = '',
    String researchField = '',
    String gender = '',
    String birthDate = '',
    String respondentStatus = '',
    String domicile = '',
    String education = '',
    String fieldOfWork = '',
  }) async {
    try {
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser == null) {
        return const Left(AuthFailure('Sesi tidak ditemukan. Silakan login ulang.'));
      }

      final updated = await _remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        institution: institution,
        academicRole: academicRole,
        researchField: researchField,
        gender: gender,
        birthDate: birthDate,
        respondentStatus: respondentStatus,
        domicile: domicile,
        education: education,
        fieldOfWork: fieldOfWork,
      );

      // `id`/`email`/`role` SELALU dari cache (user yang beneran login),
      // BUKAN dari datasource — `updateProfile` di `AuthRemoteDataSourceMock`
      // sengaja tetap identity-agnostic (nggak tau id/email/role user, biar
      // konsisten sama kontrak yang bisa dipenuhi Dio impl beneran juga) dan
      // balikin placeholder buat field itu (lihat catatan di sana); buat
      // Dio impl beneran pun email/role emang nggak diedit dari form ini.
      final merged = UserModel(
        id: cachedUser.id,
        name: updated.name,
        email: cachedUser.email,
        phone: updated.phone,
        role: cachedUser.role,
        institution: updated.institution,
        academicRole: updated.academicRole,
        researchField: updated.researchField,
        gender: updated.gender,
        birthDate: updated.birthDate,
        respondentStatus: updated.respondentStatus,
        domicile: updated.domicile,
        education: updated.education,
        fieldOfWork: updated.fieldOfWork,
      );
      await _localDataSource.updateCachedUser(merged);
      return Right(merged);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
