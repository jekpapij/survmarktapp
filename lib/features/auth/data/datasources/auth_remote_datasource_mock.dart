import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Implementasi dummy dari [AuthRemoteDataSource] — dipakai selama backend
/// beneran belum live (lihat `ApiConstants.useMockBackend`).
///
/// Kenapa ini ada (keputusan 2026-09-08): rubrik CPMK 3 (`SPESIFIKASI_
/// PROYEK_PENILAIAN.pdf`) nilai "Efisiensi Pengelolaan State" dari apakah
/// state Loading/Error/Success KETIGANYA kebukti jalan — bukan cuma
/// Loading->Error kayak yang kejadian kalau nunggu Dio timeout 30 detik ke
/// backend yang belum ada. Mock ini bikin ketiga state itu bisa didemoin
/// tanpa nunggu CPMK 5 (Integration Engine). Struktur/tanda tangan method-nya
/// PERSIS sama kayak [AuthRemoteDataSourceImpl] (implement interface yang
/// sama) — jadi swap ke backend beneran nanti tinggal ganti provider di
/// `auth_providers.dart`, nggak perlu ubah apapun di layer lain
/// (Domain/Presentation sama sekali nggak tau/peduli mana yang dipakai).
///
/// Trigger simulasi error (buat demo/testing state Error secara sengaja,
/// tanpa perlu backend beneran buat nolak kredensial):
/// - Login: password diisi persis `"salah"` -> AuthException.
/// - Register: email diisi persis `"admin@survmarkt.com"` -> ValidationException
///   (simulasi "email sudah terdaftar").
class AuthRemoteDataSourceMock implements AuthRemoteDataSource {
  const AuthRemoteDataSourceMock();

  static const _networkDelay = Duration(milliseconds: 700);

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    await Future.delayed(_networkDelay);

    if (password.trim().toLowerCase() == 'salah') {
      throw const AuthException('Email/No. HP atau password salah.');
    }

    return AuthSession(
      user: _dummyUserFor(identifier),
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(_networkDelay);

    if (email.trim().toLowerCase() == 'admin@survmarkt.com') {
      throw const ValidationException('Email sudah terdaftar. Coba email lain.');
    }

    return UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: UserRoleX.fromApiValue(role),
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(_networkDelay);
  }

  /// Heuristik simpel biar demo login bisa "masuk" sebagai role yang
  /// berbeda-beda tanpa perlu form role terpisah — ketik identifier yang
  /// mengandung kata kuncinya (mis. "admin@test.com", "resp@test.com").
  UserModel _dummyUserFor(String identifier) {
    final lower = identifier.trim().toLowerCase();
    final role = lower.contains('admin')
        ? UserRole.admin
        : lower.contains('resp')
            ? UserRole.responden
            : UserRole.peneliti;

    return UserModel(
      id: 'mock-user-${role.apiValue}',
      name: switch (role) {
        UserRole.admin => 'Admin Dummy',
        UserRole.responden => 'Responden Dummy',
        UserRole.peneliti => 'Peneliti Dummy',
      },
      email: identifier.contains('@') ? identifier : '$identifier@example.com',
      phone: '081234567890',
      role: role,
    );
  }
}
