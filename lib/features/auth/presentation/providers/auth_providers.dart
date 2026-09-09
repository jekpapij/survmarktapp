import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource_mock.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../notifiers/auth_notifier.dart';
import '../state/auth_state.dart';

/// Wiring dependency injection buat feature auth. Dipisah dari Notifier-nya
/// sendiri (auth_notifier.dart) biar gampang dibaca mana yang "wiring" dan
/// mana yang "logic".
///
/// Catatan desain: providers di bawah ini ditulis manual (bukan pakai
/// @riverpod codegen) walaupun riverpod_generator ada di pubspec — biar
/// fitur auth langsung jalan tanpa nunggu `build_runner` dulu. Feature lain
/// bebas pakai gaya codegen kalau tim mau.

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(secureStorageProvider));
});

/// Update 2026-09-08: swap Mock<->Dio lewat `ApiConstants.useMockBackend`
/// (bukan lewat `ref.watch(dioClientProvider)` yang bakal bikin DioClient
/// ke-init sia-sia pas mock aktif). Lihat komentar lengkap di
/// `auth_remote_datasource_mock.dart`.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (ApiConstants.useMockBackend) {
    // Update 2026-09-09 (bugfix role responden): `AuthRemoteDataSourceMock`
    // sekarang stateful (nyimpen registry akun ter-register) — nggak bisa
    // `const` lagi. `Provider` (bukan `autoDispose`) di sini otomatis bikin
    // instance-nya SINGLETON sepanjang app jalan, jadi registry-nya konsisten
    // dipakai bareng antara layar Register & Login. Lihat catatan lengkap di
    // `auth_remote_datasource_mock.dart`.
    return AuthRemoteDataSourceMock();
  }
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider).dio);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

/// Identifier (email/no. HP) dari login terakhir — dipakai LoginScreen buat
/// nampilin varian "Selamat Datang Kembali" (frame `recurring-login-page`).
final lastLoginIdentifierProvider = FutureProvider<String?>((ref) {
  return ref.watch(authLocalDataSourceProvider).getLastLoginIdentifier();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
});
