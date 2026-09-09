/// Base URL & endpoint path, mengacu ke PROMPT_SPEC.md §8 (API Endpoint Reference).
///
/// Backend (kerjaan Ammar, lihat CLAUDE.md) belum live saat file ini ditulis —
/// base URL di bawah cuma placeholder buat local dev (10.0.2.2 = alias
/// Android emulator ke localhost host). Integrasi beneran ke backend adalah
/// scope CPMK 5 (Integration Engine), bukan CPMK 3.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Update 2026-09-08: toggle global buat pakai [AuthRemoteDataSourceMock]
  /// (dan mock-mock fitur lain nanti, pola yang sama) selama backend beneran
  /// belum live — lihat CLAUDE.md "Konfirmasi rubrik ... CPMK 3 TIDAK butuh
  /// backend live". Default `true`. Pas backend beneran udah siap (CPMK 5),
  /// tinggal jalanin `flutter run --dart-define=USE_MOCK_BACKEND=false` atau
  /// balikin defaultValue ini ke `false` — nggak perlu ubah kode lain sama
  /// sekali (manfaat Clean Architecture: cuma provider yang diganti).
  static const bool useMockBackend = bool.fromEnvironment('USE_MOCK_BACKEND', defaultValue: true);

  // Auth — PROMPT_SPEC.md §8
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Update: "Masuk dengan Google" — SIMULASI dummy dulu malam ini (lihat
  // `AuthRemoteDataSourceMock.loginWithGoogle`), Google Sign-In BENERAN
  // (Firebase OAuth + SHA-1 key) tetap scope resmi CPMK 5 (Integration
  // Engine, "Integrasikan fitur Authentication: Email, Google Sign-In").
  // Endpoint di bawah placeholder konsisten sama pola endpoint lain di
  // file ini — `AuthRemoteDataSourceImpl.loginWithGoogle` bakal gagal
  // `NetworkException` sampai backend beneran ada, SAMA PERSIS kayak
  // `login`/`register` Dio saat ini.
  static const String googleLogin = '/auth/google';

  // Update 2026-09-08: 3 endpoint TAMBAHAN di luar PROMPT_SPEC.md §8 —
  // "Ubah Password"/"Lupa Password" self-designed (nggak ada frame Figma
  // referensi, sama kayak fitur Notifikasi), jadi path-nya nebak sendiri
  // ngikutin konvensi REST yang sama kayak endpoint auth lain. Sesuaikan
  // kalau ternyata backend beneran (kerjaan Ammar) udah punya nama path
  // yang beda pas integrasi CPMK 5.
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Update 2026-09-08: "Edit Profil" self-designed (frame Figma
  // `researcher-profile-edit`, di luar PROMPT_SPEC.md §8 juga).
  static const String updateProfile = '/auth/profile';
}
