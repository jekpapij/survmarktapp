/// Key names untuk Flutter Secure Storage. Satu tempat biar nggak ada typo
/// key yang tersebar di berbagai datasource.
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String cachedUser = 'cached_user';

  /// Dipakai buat nampilin varian "Selamat Datang Kembali" di LoginScreen
  /// (persis frame `recurring-login-page` di Figma) — bukan token, aman
  /// disimpan meski user belum tentu masih login.
  static const String lastLoginIdentifier = 'last_login_identifier';
}
