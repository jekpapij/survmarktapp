import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import 'network_retry.dart';

/// Hasil bikin transaksi Midtrans Snap — [orderId] dipakai buat listen live
/// status pembayarannya di Firestore (`wallets/{uid}/transactions/{orderId}`,
/// lihat `_WaitingPaymentDialog` di `researcher_wallet_screen.dart`),
/// [redirectUrl] dibuka di browser (Midtrans Snap "Redirect" — bukan embed
/// WebView SDK, biar nggak nambah dependency `webview_flutter` +
/// konfigurasi platform tambahan cuma buat 1 alur ini).
class MidtransDepositResult {
  const MidtransDepositResult({required this.orderId, required this.redirectUrl});

  final String orderId;
  final String redirectUrl;
}

/// CPMK 5 (Integration Engine) — Panduan Pengerjaan poin 3 ("Simulasi atau
/// integrasi nyata Payment Gateway ... buat eksekusi alur monetisasi").
/// User pilih integrasi Midtrans Sandbox BENERAN (bukan simulasi UI doang).
///
/// **Kenapa lewat serverless function, BUKAN panggil API Midtrans langsung
/// dari Flutter:** bikin transaksi Snap butuh Server Key Midtrans — secret
/// yang TIDAK BOLEH ditaro di kode client (siapa aja yang decompile APK
/// bisa nemu & nyalahgunain).
///
/// **Update 2026-09-10 — pindah host dari Firebase Cloud Functions ke
/// Supabase Edge Functions:** versi awal (`functions/index.js`, sekarang
/// DEPRECATED) pakai Firebase Cloud Functions, tapi itu WAJIB upgrade
/// project ke plan Blaze (Google minta prepayment di muka buat billing
/// account baru sebelum bisa akses jaringan keluar — biaya nyata di depan,
/// walau technically credit/bisa di-refund) — CUMA buat 1 fitur kecil ini.
/// Supabase Edge Functions ngelakuin hal yang SAMA PERSIS (pegang Server
/// Key rahasia di server, proxy ke Midtrans) tapi gratis total, nggak
/// perlu kartu kredit sama sekali. Konsekuensinya: manggilnya sekarang
/// HTTP POST biasa (bukan `cloud_functions` SDK Firebase yang otomatis
/// nempelin identitas login) — jadi ID Token Firebase Auth ditempel manual
/// sebagai header `Authorization: Bearer <token>`, diverifikasi manual di
/// sisi Edge Function (`supabase/functions/_shared/firebase.ts`).
///
/// **Setup WAJIB sebelum ini bisa jalan** (di luar kendali kode Dart, lihat
/// checklist lengkap di CLAUDE.md "CPMK 5 — Payment Gateway Midtrans via
/// Supabase"): daftar akun Sandbox di
/// https://dashboard.sandbox.midtrans.com, bikin project Supabase (gratis),
/// deploy 2 Edge Function di `supabase/functions/`, set Payment
/// Notification URL di dashboard Midtrans nunjuk ke
/// `midtrans-notification-handler` yang ke-deploy.
class MidtransService {
  const MidtransService(this._httpClient);

  final http.Client _httpClient;

  Future<MidtransDepositResult> createDeposit(int amount) async {
    final baseUrl = ApiConstants.supabaseFunctionsBaseUrl;
    if (baseUrl.isEmpty) {
      throw const ServerException(
        'SUPABASE_FUNCTIONS_URL belum di-set — jalankan dengan --dart-define, lihat checklist CLAUDE.md.',
      );
    }
    final idToken = await fb.FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan login ulang.');
    }

    try {
      final response = await withNetworkRetry(
        () => _httpClient
            .post(
              Uri.parse('$baseUrl/create-midtrans-transaction'),
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
              body: jsonEncode({'amount': amount}),
            )
            .timeout(const Duration(seconds: 20)),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw _mapErrorResponse(response.statusCode, data);
      }
      return MidtransDepositResult(
        orderId: data['orderId'] as String,
        redirectUrl: data['redirectUrl'] as String,
      );
    } on FormatException {
      throw const ServerException('Respons server pembayaran tidak valid.');
    }
  }

  Exception _mapErrorResponse(int statusCode, Map<String, dynamic> data) {
    final message = data['message'] as String? ?? 'Gagal membuat transaksi pembayaran.';
    switch (statusCode) {
      case 401:
        return AuthException(message);
      case 400:
        return ValidationException(message);
      case 502:
      case 503:
      case 504:
        return NetworkException(message);
      default:
        return ServerException(message);
    }
  }
}
