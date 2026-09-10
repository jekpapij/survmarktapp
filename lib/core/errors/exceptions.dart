/// Exception mentah dari layer data (datasource). Ditangkap & di-mapping jadi
/// [Failure] di repository impl — lihat PROMPT_SPEC.md §2.4.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;

  // CPMK 5 (Integration Engine) — Panduan Pengerjaan poin 4 ("Error
  // Handling ... yang tangguh"): sebelum ini, class-class exception di
  // bawah nggak override `toString()`, jadi kalau kepanggil lewat
  // interpolasi string polos (`'Gagal ...: $e'`, dipakai di beberapa layar
  // Wallet) hasilnya `Instance of 'ServerException'` — bukan pesan yang
  // ramah dibaca user. Belum pernah kejadian/ketauan sebelumnya karena
  // `WalletRemoteDataSourceMock` nggak pernah nge-throw sama sekali — begitu
  // `WalletRemoteDataSourceFirestore` (CPMK 5, beneran bisa gagal jaringan)
  // masuk, ini WAJIB dibenerin dulu. Berlaku buat SEMUA 5 exception di file
  // ini (manfaatnya bukan cuma buat kerjaan CPMK 5 doang).
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);
  final String message;

  @override
  String toString() => message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Invalid credentials']);
  final String message;

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;

  @override
  String toString() => message;
}
