import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../state/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AuthState.initial());

  final LoginUseCase _loginUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  /// Dipanggil dari SplashScreen — cek apakah ada sesi tersimpan (token +
  /// user cache) buat auto-login.
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();
    final result = await _getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) => state = const AuthState.unauthenticated(),
      (user) => state = user == null ? const AuthState.unauthenticated() : AuthState.authenticated(user),
    );
  }

  Future<bool> login({required String identifier, required String password}) async {
    state = const AuthState.loading();
    final result = await _loginUseCase(LoginParams(identifier: identifier, password: password));
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (user) {
        state = AuthState.authenticated(user);
        return true;
      },
    );
  }

  /// "Masuk dengan Google" — state machine Loading/Authenticated/Error
  /// SAMA PERSIS kayak `login()` di atas (SIMULASI dummy, bukan OAuth
  /// beneran — lihat catatan lengkap di `AuthRemoteDataSourceMock`).
  Future<bool> loginWithGoogle() async {
    state = const AuthState.loading();
    final result = await _loginWithGoogleUseCase(const NoParams());
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (user) {
        state = AuthState.authenticated(user);
        return true;
      },
    );
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AuthState.loading();
    final result = await _registerUseCase(
      RegisterParams(name: name, phone: phone, email: email, password: password, role: role),
    );
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (_) {
        // Sengaja balik ke unauthenticated (bukan auto-login) — register
        // endpoint nggak ngasih token, lihat catatan di auth_repository_impl.
        state = const AuthState.unauthenticated();
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _logoutUseCase(const NoParams());
    state = const AuthState.unauthenticated();
  }

  /// Update 2026-09-08: sinkronin state IN-MEMORY setelah "Edit Profil"
  /// sukses — dipanggil dari `ResearcherProfileEditScreen` abis
  /// `AuthRepository.updateProfile(...)` balikin `UserEntity` baru. Beda
  /// dari `login`/`register`/`checkAuthStatus`, ini BUKAN lewat UseCase
  /// (mutation 1x-jalan langsung dari repository, pola sama kayak
  /// `create-survey`) — cuma perlu nyuntikkan hasilnya ke `state` biar
  /// layar Profil ke-rebuild otomatis tanpa perlu restart app/login ulang
  /// (cache lokal-nya sendiri udah diupdate di repository impl).
  void updateUser(UserEntity user) {
    if (state.status != AuthStatus.authenticated) return;
    state = AuthState.authenticated(user);
  }
}
