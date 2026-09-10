import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/google_signin_outcome.dart';
import '../entities/user_entity.dart';

/// Kontrak repository auth — implementasi konkretnya di layer data
/// (lihat data/repositories/auth_repository_impl.dart). Domain layer di sini
/// murni Dart, zero Flutter dependency — PROMPT_SPEC.md §2.2.
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String identifier,
    required String password,
  });

  /// Bugfix (2026-09-10, ketemu user pas CPMK 5 Firebase udah aktif) —
  /// "Masuk sebagai Admin" (`AdminLoginScreen`) SEHARUSNYA tetap FULL DUMMY
  /// (keputusan produk 2026-09-09, TIDAK ADA alur "Daftar sebagai Admin"),
  /// TAPI karena layar itu sebelumnya reuse `login()` biasa, begitu
  /// `ApiConstants.useFirebaseBackend=true` di-nyalain (buat testing CPMK 5
  /// Auth+Wallet Researcher/Respondent), kredensial dummy `admin@survmarkt.
  /// com`/`admin123` ikut kekirim ke Firebase Auth beneran — yang jelas
  /// nolak (`"Email/No. HP atau password salah."`) karena akun itu emang
  /// nggak pernah didaftarin di Firebase. Method BARU ini sengaja SAMA
  /// SEKALI TIDAK manggil `_remoteDataSource` (Mock ATAU Firebase, dua-
  /// duanya di-skip) — langsung cache sesi dummy ke local storage doang,
  /// PERSIS pola lama `AuthRemoteDataSourceMock._dummyUserFor('admin')`,
  /// biar Admin tetap bisa "masuk" 1-tap terlepas dari backend apa yang lagi
  /// aktif (konsisten sama scope CPMK 5: Researcher/Respondent/Admin
  /// survey-listing TETAP mock, cuma Auth+Wallet beneran-nya doang).
  Future<Either<Failure, UserEntity>> loginAsDummyAdmin();

  /// "Masuk dengan Google" — Google Sign-In BENERAN via Firebase, lihat
  /// catatan lengkap di `FirebaseGoogleAuthService`/
  /// `AuthRemoteDataSourceMock.loginWithGoogle`.
  ///
  /// Balikin [GoogleSignInOutcome], BUKAN langsung [UserEntity] — akun
  /// yang UDAH terdaftar login LANGSUNG SELESAI
  /// (`GoogleSignInOutcome.loggedIn`), tapi akun BARU balikin
  /// `GoogleSignInOutcome.needsRoleSelection` (UI WAJIB nampilin dialog
  /// pilih role dulu, baru panggil [completeGoogleRegistration]) — lihat
  /// catatan lengkap di `GoogleSignInOutcome`.
  Future<Either<Failure, GoogleSignInOutcome>> loginWithGoogle();

  /// Finalisasi akun Google BARU (dipanggil abis [loginWithGoogle]
  /// balikin `needsRoleSelection == true` DAN user milih role di dialog).
  Future<Either<Failure, UserEntity>> completeGoogleRegistration({
    required String googleId,
    required String email,
    required String name,
    required UserRole role,
  });

  /// Dipanggil kalau user BATAL di dialog pilih role (nutup tanpa milih)
  /// abis [loginWithGoogle] balikin `needsRoleSelection == true` — clear
  /// sesi Google/Firebase yang KEBURU kebentuk pas [loginWithGoogle]
  /// (proses pilih-akun-nya udah kepake), BUKAN cuma UI-nya doang, biar
  /// tap "Masuk dengan Google" berikutnya NAMPILIN LAGI dialog pilih akun
  /// Google (bukan auto-pilih akun yang tadi diam-diam, karena SDK Google
  /// Sign-In nge-cache akun terakhir sampai eksplisit `signOut()`). Selalu
  /// balikin sukses (best-effort, no-op kalau nggak ada sesi yang perlu
  /// di-clear).
  Future<Either<Failure, void>> cancelGoogleSignIn();

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<Either<Failure, void>> logout();

  /// Null kalau tidak ada sesi tersimpan (belum pernah login / udah logout).
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  // Update 2026-09-08: 3 method baru buat "Ubah Password"/"Lupa Password"
  // (self-designed, nggak ada frame Figma — lihat CLAUDE.md, sama kayak
  // fitur Notifikasi). Endpoint-nya di luar PROMPT_SPEC.md §8 asli, lihat
  // catatan di `ApiConstants`.

  /// Ubah password user yang LAGI LOGIN. `oldPassword` divalidasi di layer
  /// data (mock: throw [AuthFailure] kalau salah, sama pola kayak `login`).
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Langkah 1 alur "Lupa Password" — kirim link/kode reset ke
  /// email/No. HP. Mock nggak beneran ngirim apa-apa (itu scope CPMK 5),
  /// cuma validasi identifier "terdaftar".
  Future<Either<Failure, void>> requestPasswordReset({required String identifier});

  /// Langkah 2 — set password baru, pakai identifier yang sama dari
  /// langkah 1 (bukan token/OTP beneran — di luar scope mock CPMK 3).
  Future<Either<Failure, void>> resetPassword({
    required String identifier,
    required String newPassword,
  });

  // Update 2026-09-08: "Edit Profil" (self-designed, frame Figma
  // `researcher-profile-edit` node 77:2654) — lihat CLAUDE.md.

  /// Update data profil user yang LAGI LOGIN. Balikin [UserEntity] yang
  /// udah keupdate (dipakai caller buat sinkronin `AuthNotifier.state`,
  /// bukan cuma cache lokal).
  // Update 2026-09-09: `institution`/`academicRole`/`researchField` (isian
  // khusus Peneliti) diganti dari `required` jadi OPSIONAL (default ''), +
  // 6 param baru (`gender`/`birthDate`/`respondentStatus`/`domicile`/
  // `education`/`fieldOfWork`, isian khusus Responden, dari `respondent-
  // edit-profile` node 77:3214) — 1 method `updateProfile` ini sekarang
  // dipakai BERSAMA sama `researcher-profile-edit` DAN `respondent-edit-
  // profile`, tiap caller cukup ngisi param yang relevan sama role-nya
  // doang, sisanya default `''` yang aman (nggak nge-wipe data section lain
  // karena section lain emang udah pasti `''` buat role yang beda — pola
  // sama kayak `forRole` di `WalletRepository`).
  Future<Either<Failure, UserEntity>> updateProfile({
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
  });
}
