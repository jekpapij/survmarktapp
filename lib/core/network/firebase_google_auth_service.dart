import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

/// Hasil sign-in Google BENERAN (Firebase Authentication + Google Sign-In
/// SDK) — beda dari simulasi dummy sebelumnya (profil hardcoded "Alex
/// Wijaya" di `AuthRemoteDataSourceMock` versi lama, sekarang diganti).
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.idToken,
  });

  final String uid;
  final String email;
  final String name;
  final String? photoUrl;

  /// Dikirim ke backend (`AuthRemoteDataSourceImpl.loginWithGoogle`) buat
  /// diverifikasi pas backend beneran (CPMK 5) udah live. `null` kalau
  /// Google Sign-In SDK nggak ngasih idToken (jarang, tapi mungkin kalau
  /// setup OAuth client di Firebase Console belum sempurna).
  final String? idToken;
}

/// Wrapper tipis `google_sign_in` (buka dialog pilih akun Google) +
/// `firebase_auth` (tukar credential Google jadi sesi Firebase). SATU
/// instance ini di-share (singleton lewat Provider) antara
/// `AuthRemoteDataSourceMock`, `AuthRemoteDataSourceImpl`, DAN
/// `AuthRepositoryImpl` (buat sign-out) — lihat `auth_providers.dart`.
///
/// **Identitas Google-nya SELALU nyata**, terlepas dari
/// `ApiConstants.useMockBackend` — toggle itu cuma ngatur REST call
/// SESUDAHNYA (mock in-memory vs Dio ke backend beneran), BUKAN proses
/// pilih-akun-Google-nya sendiri (itu selalu bicara ke Google/Firebase
/// beneran, nggak ada versi "mock"-nya).
///
/// **Setup WAJIB sebelum ini bisa jalan** (di luar kendali kode Dart —
/// lihat checklist lengkap di CLAUDE.md "Update — Google Sign-In BENERAN
/// via Firebase"): (1) bikin project di https://console.firebase.google.com,
/// (2) daftarin app Android dengan package `com.survmarkt.survmarkt` +
/// SHA-1 debug keystore, (3) aktifin provider "Google" di Firebase
/// Authentication > Sign-in method, (4) download `google-services.json`
/// & taruh di `android/app/google-services.json`.
///
/// Kalau langkah-langkah itu belum kelar: `Firebase.initializeApp()` di
/// `main.dart` di-`try/catch` (app tetap jalan normal buat fitur lain,
/// nggak crash total), dan [signIn] di sini bakal throw — ke-`catch`
/// generik di `AuthRepositoryImpl.loginWithGoogle()`/datasource,
/// tampil sebagai SnackBar error di `LoginScreen`, BUKAN bikin app crash.
class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService({GoogleSignIn? googleSignIn, fb.FirebaseAuth? firebaseAuth})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']),
        _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn;
  final fb.FirebaseAuth _firebaseAuth;

  /// Buka dialog pilih akun Google -> tukar jadi sesi Firebase. Balikin
  /// `null` kalau user NUTUP dialog/batal pilih akun (bagian normal dari
  /// alurnya, BUKAN error) — caller yang mutusin gimana nampilin ini ke
  /// user (lihat `AuthRemoteDataSourceMock.loginWithGoogle`/
  /// `AuthRemoteDataSourceImpl.loginWithGoogle`, dua-duanya nge-throw
  /// `AuthException('Login Google dibatalkan.')` pas null).
  Future<GoogleAuthResult?> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;

    return GoogleAuthResult(
      uid: firebaseUser?.uid ?? googleUser.id,
      email: firebaseUser?.email ?? googleUser.email,
      name: firebaseUser?.displayName ?? googleUser.displayName ?? 'Pengguna Google',
      photoUrl: firebaseUser?.photoURL ?? googleUser.photoUrl,
      idToken: googleAuth.idToken,
    );
  }

  /// Dipanggil bareng `AuthRepository.logout()` biar sesi Google-nya juga
  /// beneran ke-clear (bukan cuma token app-nya doang) — kalau nggak,
  /// `signIn()` berikutnya auto-pilih akun yang sama tanpa nampilin
  /// dialog lagi (nggak kerasa kayak "logout" beneran dari sisi Google).
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
