import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// CPMK 5 (Integration Engine) — Panduan Pengerjaan poin 4: "Terapkan Error
/// Handling dan penanganan jaringan yang tangguh (misal: timeout, retry
/// mechanism)". Dipakai buat ngebungkus SEMUA panggilan Firestore (Auth+
/// Wallet) + panggilan HTTP ke Supabase Edge Function (Payment Gateway
/// Midtrans, lihat `midtrans_service.dart`) — beda dari Dio yang udah punya
/// `connectTimeout`/`receiveTimeout` bawaan sendiri, SDK Firestore/`http`
/// polos nggak punya retry otomatis buat error SEMENTARA (device baru
/// pindah WiFi<->data seluler, sinyal lemah sesaat, dst).
///
/// Update 2026-09-10: dulunya juga nangkep `FirebaseFunctionsException`
/// (pas Payment Gateway masih Firebase Cloud Functions) — sekarang
/// digantikan `http.ClientException` sejak Midtrans pindah ke Supabase Edge
/// Functions (dipanggil pakai HTTP POST biasa, bukan SDK Firebase lagi).
///
/// Cuma retry buat kode error yang KEMUNGKINAN sementara (`unavailable`,
/// `deadline-exceeded`, `aborted` buat Firestore; kegagalan koneksi buat
/// `http`) — error PERMANEN (`permission-denied`, `not-found`,
/// `invalid-argument`, dst) LANGSUNG gagal tanpa buang waktu retry sia-sia
/// (lagian nggak bakal berubah hasilnya walau dicoba ulang). Exception ASLI
/// (tipe & `.code`-nya) selalu di-rethrow apa adanya kalau semua percobaan
/// abis — caller (datasource/service) yang tetap tanggung jawab nge-map ke
/// [core/errors/exceptions.dart] biar pesannya ramah user, pola
/// `_mapDioException` yang udah ada di `AuthRemoteDataSourceImpl` (Dio).
Future<T> withNetworkRetry<T>(Future<T> Function() action, {int retries = 2}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } on FirebaseException catch (e) {
      if (!_isTransientCode(e.code) || attempt >= retries) rethrow;
    } on http.ClientException {
      if (attempt >= retries) rethrow;
    } on TimeoutException {
      if (attempt >= retries) rethrow;
    }
    attempt++;
    // Backoff pendek & makin lama tiap percobaan (400ms, 800ms, ...) — cukup
    // buat ngelewatin gangguan sesaat, tapi nggak bikin user nunggu lama
    // banget kalau ternyata emang beneran gagal.
    await Future.delayed(Duration(milliseconds: 400 * attempt));
  }
}

bool _isTransientCode(String code) {
  return code == 'unavailable' || code == 'deadline-exceeded' || code == 'aborted';
}
