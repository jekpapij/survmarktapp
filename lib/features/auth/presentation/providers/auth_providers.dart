import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/firebase_google_auth_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource_mock.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/cancel_google_signin_usecase.dart';
import '../../domain/usecases/complete_google_registration_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
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

/// Update — Google Sign-In BENERAN (Firebase): SATU instance di-share
/// (Provider singleton) ke `AuthRemoteDataSourceMock`,
/// `AuthRemoteDataSourceImpl`, DAN `AuthRepositoryImpl` (buat sign-out).
/// Identitas Google-nya SELALU nyata terlepas dari
/// `ApiConstants.useMockBackend` — lihat catatan lengkap di
/// `FirebaseGoogleAuthService` buat checklist setup Firebase Console yang
/// WAJIB kelar duluan (SHA-1, `google-services.json`, dst).
final firebaseGoogleAuthServiceProvider = Provider<FirebaseGoogleAuthService>((ref) {
  return FirebaseGoogleAuthService();
});

/// Update 2026-09-08: swap Mock<->Dio lewat `ApiConstants.useMockBackend`
/// (bukan lewat `ref.watch(dioClientProvider)` yang bakal bikin DioClient
/// ke-init sia-sia pas mock aktif). Lihat komentar lengkap di
/// `auth_remote_datasource_mock.dart`.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final googleAuthService = ref.watch(firebaseGoogleAuthServiceProvider);
  if (ApiConstants.useMockBackend) {
    // Update 2026-09-09 (bugfix role responden): `AuthRemoteDataSourceMock`
    // sekarang stateful (nyimpen registry akun ter-register) — nggak bisa
    // `const` lagi. `Provider` (bukan `autoDispose`) di sini otomatis bikin
    // instance-nya SINGLETON sepanjang app jalan, jadi registry-nya konsisten
    // dipakai bareng antara layar Register & Login. Lihat catatan lengkap di
    // `auth_remote_datasource_mock.dart`.
    return AuthRemoteDataSourceMock(googleAuthService: googleAuthService);
  }
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider).dio, googleAuthService);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    googleAuthService: ref.watch(firebaseGoogleAuthServiceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  return LoginWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final completeGoogleRegistrationUseCaseProvider = Provider<CompleteGoogleRegistrationUseCase>((ref) {
  return CompleteGoogleRegistrationUseCase(ref.watch(authRepositoryProvider));
});

final cancelGoogleSignInUseCaseProvider = Provider<CancelGoogleSignInUseCase>((ref) {
  return CancelGoogleSignInUseCase(ref.watch(authRepositoryProvider));
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
    loginWithGoogleUseCase: ref.watch(loginWithGoogleUseCaseProvider),
    completeGoogleRegistrationUseCase: ref.watch(completeGoogleRegistrationUseCaseProvider),
    cancelGoogleSignInUseCase: ref.watch(cancelGoogleSignInUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
});
