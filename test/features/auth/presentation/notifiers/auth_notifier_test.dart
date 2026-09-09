import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survmarkt/core/errors/failures.dart';
import 'package:survmarkt/features/auth/domain/entities/user_entity.dart';
import 'package:survmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:survmarkt/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:survmarkt/features/auth/domain/usecases/login_usecase.dart';
import 'package:survmarkt/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:survmarkt/features/auth/domain/usecases/logout_usecase.dart';
import 'package:survmarkt/features/auth/domain/usecases/register_usecase.dart';
import 'package:survmarkt/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:survmarkt/features/auth/presentation/state/auth_state.dart';

/// Unit test buat `AuthNotifier` — INI test paling penting buat CPMK 3 poin
/// 3 & 4 ("hubungkan interaksi UI dengan State Management, tangani kondisi
/// Initial/Loading/Success/Error" + "Unit Test buat memvalidasi fungsi
/// logika bisnis utama"). `AuthRepository` di-fake TANGAN (bukan Mockito
/// generated) karena `build_runner` nggak bisa dijalankan di lingkungan
/// nulis test ini — nggak ada `.mocks.dart` yang ke-generate.
class _FakeAuthRepository implements AuthRepository {
  /// Diset per-test buat nentuin hasil `login()` selanjutnya.
  Either<Failure, UserEntity>? loginResult;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String identifier,
    required String password,
  }) async {
    return loginResult ?? const Left(AuthFailure());
  }

  // Bugfix (laporan user — `flutter analyze` gagal, "Missing concrete
  // implementation of 'abstract class AuthRepository.loginWithGoogle'"):
  // method ini ketinggalan pas `AuthRepository` diperluas buat "Masuk
  // dengan Google" (dua update terpisah setelah test ini ditulis) — fake
  // repo di sini WAJIB implement SEMUA method abstract-nya. Reuse
  // `loginResult` yang SAMA (bukan field terpisah) — cukup buat test yang
  // ada sekarang, dua-duanya balikin `Either<Failure, UserEntity>`.
  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle() async {
    return loginResult ?? const Left(AuthFailure());
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return const Right(testUser);
  }

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async => const Right(null);

  @override
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> requestPasswordReset({required String identifier}) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> resetPassword({
    required String identifier,
    required String newPassword,
  }) async =>
      const Right(null);

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
  }) async =>
      const Right(testUser);
}

const testUser = UserEntity(
  id: 'u1',
  name: 'Budi Tester',
  email: 'budi@test.com',
  phone: '0812',
  role: UserRole.peneliti,
);

AuthNotifier _buildNotifier(_FakeAuthRepository repo) {
  return AuthNotifier(
    loginUseCase: LoginUseCase(repo),
    // Bugfix (sama kayak catatan di `loginWithGoogle()` atas) —
    // `AuthNotifier` sekarang butuh `loginWithGoogleUseCase` juga.
    loginWithGoogleUseCase: LoginWithGoogleUseCase(repo),
    registerUseCase: RegisterUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    getCurrentUserUseCase: GetCurrentUserUseCase(repo),
  );
}

void main() {
  late _FakeAuthRepository fakeRepo;
  late AuthNotifier notifier;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
    notifier = _buildNotifier(fakeRepo);
  });

  test('state awal adalah AuthStatus.initial', () {
    expect(notifier.state.status, AuthStatus.initial);
    expect(notifier.state.user, isNull);
    expect(notifier.state.errorMessage, isNull);
  });

  group('login', () {
    test('sukses → state akhir authenticated berisi user, return true', () async {
      fakeRepo.loginResult = const Right(testUser);

      final success = await notifier.login(identifier: 'budi@test.com', password: 'rahasia');

      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user, testUser);
      expect(notifier.state.errorMessage, isNull);
    });

    test('gagal → state akhir error berisi pesan, return false', () async {
      fakeRepo.loginResult = const Left(AuthFailure('Email/No. HP atau password salah.'));

      final success = await notifier.login(identifier: 'salah@test.com', password: 'salah');

      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, 'Email/No. HP atau password salah.');
      expect(notifier.state.user, isNull);
    });

    test('sesaat setelah dipanggil (sebelum awaited) state langsung jadi loading', () async {
      fakeRepo.loginResult = const Right(testUser);

      // SENGAJA nggak langsung di-`await` — memanfaatkan semantik Dart
      // "kode jalan sinkron sampai `await` pertama". `AuthNotifier.login`
      // nge-set `state = AuthState.loading()` sebagai baris PERTAMA sebelum
      // `await _loginUseCase(...)`, jadi begitu `Future` ini dibuat (belum
      // di-await), state notifier udah pasti `loading` — nggak gantung ke
      // detail API `StateNotifier.addListener`/`fireImmediately`.
      final future = notifier.login(identifier: 'budi@test.com', password: 'rahasia');
      expect(notifier.state.status, AuthStatus.loading);

      await future;
      expect(notifier.state.status, AuthStatus.authenticated);
    });
  });

  group('logout', () {
    test('mengembalikan state ke unauthenticated', () async {
      fakeRepo.loginResult = const Right(testUser);
      await notifier.login(identifier: 'budi@test.com', password: 'rahasia');
      expect(notifier.state.status, AuthStatus.authenticated);

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
    });
  });

  group('updateUser', () {
    test('kalau belum authenticated, dipanggil tidak berefek apa-apa', () {
      expect(notifier.state.status, AuthStatus.initial);
      notifier.updateUser(testUser);
      expect(notifier.state.status, AuthStatus.initial);
    });

    test('kalau authenticated, mengganti user di state dengan yang baru', () async {
      fakeRepo.loginResult = const Right(testUser);
      await notifier.login(identifier: 'budi@test.com', password: 'rahasia');

      final updated = testUser.copyWith(name: 'Budi Sudah Update');
      notifier.updateUser(updated);

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.name, 'Budi Sudah Update');
    });
  });
}
