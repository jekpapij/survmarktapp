import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/firebase_google_auth_service.dart';
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
///
/// **Bugfix 2026-09-09 (laporan user — "register+login jadi responden
/// ketendang ke researcher"):** dulu class ini `const`/stateless, dan
/// `login()` NEBAK role user cuma dari substring identifier-nya sendiri
/// (`_dummyUserFor` — "admin"/"resp" di email/HP, default Peneliti). Role
/// yang BENERAN dipilih user di dropdown "Daftar Sebagai" pas register sama
/// sekali nggak kesimpen di manapun — jadi user yang daftar sebagai
/// Responden pakai email biasa (nggak ngandung kata "resp") bakal login
/// balik sebagai Peneliti (fallback default heuristik lama). Fix: class ini
/// sekarang STATEFUL — nyimpen `_registeredUsers` (di memori, key by email
/// & HP ternormalisasi) tiap `register()` sukses, dan `login()` CEK REGISTRY
/// INI DULU sebelum jatuh ke heuristik lama. Heuristik lama TETAP
/// dipertahankan sebagai fallback — masih berguna buat quick-login demo
/// tanpa perlu register dulu (mis. langsung login pakai "admin@test.com").
class AuthRemoteDataSourceMock implements AuthRemoteDataSource {
  AuthRemoteDataSourceMock({required FirebaseGoogleAuthService googleAuthService})
      : _googleAuthService = googleAuthService;

  final FirebaseGoogleAuthService _googleAuthService;

  static const _networkDelay = Duration(milliseconds: 700);

  /// Registry akun yang udah pernah `register()` di sesi app ini (reset lagi
  /// kalau app di-restart total — sesuai keterbatasan mock in-memory, sama
  /// kayak `ResearcherRemoteDataSourceMock`/`NotificationRemoteDataSourceMock`
  /// yang juga stateful). Key: email & nomor HP, DUA-DUANYA (huruf
  /// kecil+trim) — biar user bisa login pakai salah satu, konsisten sama
  /// `Validators.emailOrPhone` di form login.
  final Map<String, UserModel> _registeredUsers = {};

  String _normalize(String value) => value.trim().toLowerCase();

  void _rememberRegisteredUser(UserModel user) {
    _registeredUsers[_normalize(user.email)] = user;
    if (user.phone.isNotEmpty) {
      _registeredUsers[_normalize(user.phone)] = user;
    }
  }

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    await Future.delayed(_networkDelay);

    if (password.trim().toLowerCase() == 'salah') {
      throw const AuthException('Email/No. HP atau password salah.');
    }

    // Cek dulu apakah identifier ini beneran pernah register (role-nya
    // ambil dari situ, BUKAN ditebak dari teks identifier) — baru fallback
    // ke heuristik lama kalau belum pernah register (demo/quick-login).
    final registered = _registeredUsers[_normalize(identifier)];

    return AuthSession(
      user: registered ?? _dummyUserFor(identifier),
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }

  /// "Masuk dengan Google" — Google Sign-In BENERAN via
  /// `FirebaseGoogleAuthService` (Firebase Auth + Google Sign-In SDK),
  /// BUKAN dummy hardcoded lagi (versi sebelumnya: profil "Alex Wijaya"
  /// yang di-fix). Backend REST-nya TETAP mock (`_registeredUsers` in-
  /// memory, sejalan `ApiConstants.useMockBackend`) — cuma identitas
  /// Google-nya yang sekarang 100% nyata (email/nama/foto beneran dari
  /// akun Google yang dipilih user di dialog). Role tetap default
  /// `responden` buat akun yang belum pernah `register()` manual
  /// sebelumnya (alasan sama kayak versi dummy dulu — target utama
  /// SurvMarkt = mahasiswa, lebih plausible pakai akun Google pribadi
  /// buat isi survei, dibanding Peneliti yang biasanya institusi).
  /// Session hasilnya TETAP di-`cacheSession` lewat `AuthLocalDataSource`
  /// yang SAMA persis kayak `login()` biasa (lihat
  /// `AuthRepositoryImpl.login`) — jadi ini juga sekalian bukti tambahan
  /// integrasi local storage CPMK 4, bukan cuma UI kosmetik.
  @override
  Future<AuthSession> loginWithGoogle() async {
    final googleResult = await _googleAuthService.signIn();
    if (googleResult == null) {
      throw const AuthException('Login Google dibatalkan.');
    }
    await Future.delayed(_networkDelay);

    final normalizedEmail = _normalize(googleResult.email);
    final user = _registeredUsers[normalizedEmail] ??
        UserModel(
          id: googleResult.uid,
          name: googleResult.name,
          email: googleResult.email,
          phone: '',
          role: UserRole.responden,
        );
    // Simpen/update registry biar login BERIKUTNYA (email/password ATAU
    // Google lagi) konsisten ketemu user yang SAMA, bukan bikin identitas
    // baru tiap kali dia pilih akun Google yang sama.
    _rememberRegisteredUser(user);

    return AuthSession(
      user: user,
      accessToken: 'firebase-${googleResult.uid}',
      refreshToken: 'firebase-${googleResult.uid}',
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

    final resolvedRole = UserRoleX.fromApiValue(role);
    final user = UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: resolvedRole,
      // Sama kayak dummy quick-login: institusi cuma keisi default buat
      // Peneliti (nyamain contoh Figma `researcher-profile`), Responden
      // dikosongin (belum ada frame profil buat role itu yang butuh
      // nampilinnya) — user bisa lengkapin sendiri lewat Edit Profil.
      institution: resolvedRole == UserRole.peneliti ? 'Universitas Indonesia' : '',
    );
    _rememberRegisteredUser(user);
    return user;
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
  // Update 2026-09-09: validasi "field wajib" DIPINDAH ke masing-masing
  // SCREEN (`researcher_profile_edit_screen.dart`/`respondent_edit_profile_
  // screen.dart`, per Form validator + manual check kayak `_academicRole`),
  // BUKAN di sini lagi — soalnya method ini sekarang dipakai 2 role yang
  // field wajibnya beda total (institution+academicRole buat Peneliti vs
  // gender+birthDate+respondentStatus+domicile+education buat Responden),
  // jadi nggak ada 1 aturan wajib yang bener buat KEDUANYA sekaligus di
  // level datasource. Yang tetep dicek DI SINI cuma yang UNIVERSAL ke semua
  // role: nama & nomor HP.
  Future<UserModel> updateProfile({
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
    await Future.delayed(_networkDelay);

    if (name.trim().isEmpty || phone.trim().isEmpty) {
      throw const ValidationException('Nama dan nomor HP wajib diisi.');
    }

    // Method ini SENGAJA identity-agnostic (nggak nyari/nyocokin ke
    // `_registeredUsers` — beda dari `login()`/`register()` di atas yang
    // udah dibikin stateful pas bugfix 2026-09-09), karena signature-nya
    // nggak dikasih tau ini profil SIAPA yang lagi diedit. id/email/role di
    // bawah cuma PLACEHOLDER — `AuthRepositoryImpl` yang gabungin balik
    // sama data asli dari cache lokal (lihat catatan di sana), jadi
    // placeholder ini nggak pernah beneran ditampilin ke user.
    return UserModel(
      id: '',
      name: name,
      email: '',
      phone: phone,
      role: UserRole.peneliti,
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
