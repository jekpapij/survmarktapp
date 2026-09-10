import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/firebase_google_auth_service.dart';
import '../../domain/entities/google_signin_outcome.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required FirebaseGoogleAuthService googleAuthService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _googleAuthService = googleAuthService;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final FirebaseGoogleAuthService _googleAuthService;

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

  /// Lihat doc-comment lengkap di `AuthRepository.loginAsDummyAdmin` —
  /// sengaja TIDAK menyentuh `_remoteDataSource` sama sekali (Mock maupun
  /// Firebase), cuma cache sesi dummy langsung ke local storage. Satu-
  /// satunya exception yang mungkin muncul di sini adalah `CacheException`
  /// dari `cacheSession()` (mis. secure storage device-nya sendiri
  /// bermasalah) — di-map ke `CacheFailure`, pola sama kayak
  /// `getCurrentUser()` di bawah.
  @override
  Future<Either<Failure, UserEntity>> loginAsDummyAdmin() async {
    try {
      const user = UserModel(
        id: 'mock-user-admin',
        name: 'Admin Dummy',
        email: 'admin@survmarkt.com',
        phone: '081234567890',
        role: UserRole.admin,
      );
      await _localDataSource.cacheSession(
        user: user,
        accessToken: 'dummy-admin-token',
        refreshToken: 'dummy-admin-token',
      );
      await _localDataSource.saveLastLoginIdentifier(user.email);
      return const Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  /// "Masuk dengan Google" — kalau akun UDAH terdaftar, reuse PERSIS pola
  /// caching `login()` di atas (`cacheSession` + `saveLastLoginIdentifier`),
  /// jadi abis "login Google" auto-login (`checkAuthStatus`) & varian
  /// "Selamat Datang Kembali" di `LoginScreen` tetap jalan normal, sama
  /// kayak abis login email/HP biasa. Kalau akun BARU (`needsRoleSelection`),
  /// TIDAK ADA yang di-cache di sini — belum ada sesi buat di-cache, nunggu
  /// [completeGoogleRegistration] abis user milih role.
  @override
  Future<Either<Failure, GoogleSignInOutcome>> loginWithGoogle() async {
    try {
      final start = await _remoteDataSource.loginWithGoogle();
      if (start.needsRoleSelection) {
        return Right(GoogleSignInOutcome.needsRoleSelection(
          googleId: start.googleId!,
          email: start.email!,
          name: start.name!,
        ));
      }
      final session = start.session!;
      await _localDataSource.cacheSession(
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await _localDataSource.saveLastLoginIdentifier(session.user.email);
      return Right(GoogleSignInOutcome.loggedIn(session.user));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  /// Finalisasi akun Google BARU — pola caching SAMA PERSIS kayak
  /// `loginWithGoogle()`/`login()` di atas.
  @override
  Future<Either<Failure, UserEntity>> completeGoogleRegistration({
    required String googleId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    try {
      final session = await _remoteDataSource.completeGoogleRegistration(
        googleId: googleId,
        email: email,
        name: name,
        role: role,
      );
      await _localDataSource.cacheSession(
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await _localDataSource.saveLastLoginIdentifier(session.user.email);
      return Right(session.user);
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

  /// Bugfix (laporan user — abis Batal di dialog pilih role, tap "Masuk
  /// dengan Google" lagi malah LANGSUNG ke dialog pilih role akun yang
  /// tadi, bukan balik nampilin pilihan akun Google): `signIn()` di
  /// [FirebaseGoogleAuthService] udah kepake buat mastiin akun (pas
  /// [loginWithGoogle] balikin `needsRoleSelection`), jadi SDK Google
  /// Sign-In udah nge-cache akun itu — persis alasan yang sama kayak
  /// kenapa `logout()` di bawah juga manggil `_googleAuthService.signOut()`
  /// (lihat komentarnya). Best-effort: try/catch, SELALU `Right(null)`.
  @override
  Future<Either<Failure, void>> cancelGoogleSignIn() async {
    try {
      await _googleAuthService.signOut();
    } catch (_) {
      // Nggak masalah kalau gagal (mis. emang belum ada sesi Google/
      // Firebase buat di-clear) — efeknya cuma UX, bukan data rusak.
    }
    return const Right(null);
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
    }
    try {
      // Update — Google Sign-In BENERAN: clear juga sesi Google/Firebase-
      // nya sendiri, BUKAN cuma token app — kalau nggak, `signIn()`
      // berikutnya auto-pilih akun Google yang sama tanpa nampilin dialog
      // lagi (nggak kerasa kayak "keluar" beneran dari sisi Google). Aman
      // buat user yang TIDAK PERNAH login pakai Google sama sekali —
      // `FirebaseGoogleAuthService.signOut()` no-op kalau emang belum ada
      // sesi Google/Firebase buat di-clear.
      await _googleAuthService.signOut();
    } catch (_) {
      // Sama alasannya kayak di atas — jangan sampai logout GAGAL TOTAL
      // cuma gara-gara sign-out Google/Firebase error (mis. belum ada
      // sesi Firebase sama sekali).
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
