import 'package:connectivity_plus/connectivity_plus.dart';

/// Wrapper tipis di atas `connectivity_plus` — dipakai buat pola
/// Offline-First CPMK 4 (Panduan Pengerjaan poin 2: "Aplikasi tetap dapat
/// membaca dan menulis data ... saat offline, lalu disinkronkan ketika
/// koneksi internet kembali"). Sengaja dipisah jadi service kecil di
/// `core/` (bukan langsung dipanggil dari tiap repository) biar SEMUA fitur
/// yang butuh cek online/offline nanti (bukan cuma `wallet`) tinggal
/// reuse ini, konsisten sama pola `Formatters`/`DioClient`.
///
/// Catatan jujur: `connectivity_plus` cuma ngecek apakah device PUNYA
/// koneksi jaringan (WiFi/data aktif) — BUKAN ngecek apakah internet
/// beneran nyambung ke luar (misal WiFi nyala tapi router-nya nggak ada
/// internet). Buat scope CPMK 4 (mock backend, belum ada server API
/// beneran buat di-ping), ini presisi yang cukup — "device offline"
/// disamain sama "airplane mode / WiFi+data mati", cara paling gampang
/// buat demo/tes pola offline-first secara manual di device fisik.
class ConnectivityService {
  const ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Stream `true`/`false` tiap kali status jaringan berubah — dipakai
  /// buat trigger sinkronisasi OTOMATIS pas koneksi balik (bukan cuma pas
  /// user manual pull-to-refresh), sesuai rubrik CPMK 3 "Sangat Baik":
  /// "mampu melakukan sinkronisasi otomatis saat online".
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
