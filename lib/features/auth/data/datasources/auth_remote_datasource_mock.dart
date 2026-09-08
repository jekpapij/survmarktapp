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
/// - Ubah Password: "Password Lama" diisi persis `"salah"` -> AuthException
///   (pola sama kayak login).
/// - Lupa Password (langkah 1): identifier diisi persis
///   `"notfound@survmarkt.com"` -> ValidationException (simulasi "nggak
///   terdaftar"). Langkah 2 (set password baru) SELALU sukses di mock —
///   identifier-nya udah "divalidasi" di langkah 1.
/// - Edit Profil: salah satu field wajib (Nama/HP/Peran/Institusi)
///   dikosongin -> ValidationException.
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

  @override
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    await Future.delayed(_networkDelay);

    if (oldPassword.trim().toLowerCase() == 'salah') {
      throw const AuthException('Password lama salah.');
    }
  }

  @override
  Future<void> requestPasswordReset({required String identifier}) async {
    await Future.delayed(_networkDelay);

    if (identifier.trim().toLowerCase() == 'notfound@survmarkt.com') {
      throw const ValidationException('Email/No. HP tidak terdaftar di SurvMarkt.');
    }
  }

  @override
  Future<void> resetPassword({required String identifier, required String newPassword}) async {
    await Future.delayed(_networkDelay);
    // Selalu sukses — identifier-nya udah "divalidasi" di langkah 1
    // (requestPasswordReset). Nggak ada token/OTP beneran buat dicek di
    // sini (di luar scope mock CPMK 3).
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    required String institution,
    required String academicRole,
    required String researchField,
  }) async {
    await Future.delayed(_networkDelay);

    if (name.trim().isEmpty || phone.trim().isEmpty || institution.trim().isEmpty || academicRole.trim().isEmpty) {
      throw const ValidationException('Semua field wajib (*) harus diisi.');
    }

    // Mock ini STATELESS (const, nggak nyimpen sesi siapa yang lagi login —
    // beda dari `ResearcherRemoteDataSourceMock` yang emang nyimpen state).
    // id/email/role di bawah cuma PLACEHOLDER — `AuthRepositoryImpl` yang
    // gabungin balik sama data asli dari cache lokal (lihat catatan di
    // sana), jadi placeholder ini nggak pernah beneran ditampilin ke user.
    return UserModel(
      id: '',
      name: name,
      email: '',
      phone: phone,
      role: UserRole.peneliti,
      institution: institution,
      academicRole: academicRole,
      researchField: researchField,
    );
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
      // Update 2026-09-08: dummy institusi buat card "Informasi Akun" di
      // frame `researcher-profile` — cuma diisi buat Peneliti (nyamain
      // Figma "Universitas Indonesia"), Responden/Admin dikosongin karena
      // belum ada frame profil buat role itu yang butuh nampilinnya.
      institution: role == UserRole.peneliti ? 'Universitas Indonesia' : '',
    );
  }
}
