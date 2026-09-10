import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/firebase_google_auth_service.dart';
import '../../../../core/network/network_retry.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// CPMK 5 (Integration Engine) — implementasi BENERAN dari
/// [AuthRemoteDataSource], backend-nya Firebase (Authentication buat
/// identitas/kredensial, Firestore collection `users/{uid}` buat profil) —
/// keputusan scope user: "Auth + Wallet dulu" pakai Firebase (project-nya
/// udah ada dari setup Google Sign-In sebelumnya, tinggal nyalain
/// Firestore). Dipilih lewat `ApiConstants.useFirebaseBackend`, GANTIIN
/// [AuthRemoteDataSourceMock] (BUKAN `AuthRemoteDataSourceImpl` Dio — itu
/// buat skema Custom REST yang nggak jadi dipilih) — implement interface
/// yang SAMA PERSIS, jadi Domain/Presentation layer nggak nyentuh/tau sama
/// sekali (manfaat Clean Architecture yang sama kayak swap Mock<->Impl).
///
/// **Kenapa "Masuk dengan Google" (`loginWithGoogle`/
/// `completeGoogleRegistration`) TETAP butuh implementasi di sini juga**
/// (padahal identitas Google-nya "SELALU nyata" udah dari update
/// sebelumnya): itu betul buat SIGN-IN-nya (`FirebaseGoogleAuthService`
/// selalu dipanggil beneran apapun backend-nya), tapi PROFIL user (nama/
/// role/dst) tetap disimpen beda-beda tergantung backend — Mock nyimpen di
/// `Map` in-memory, di sini (Firebase) disimpen beneran di Firestore
/// `users/{uid}` — dokumen yang SAMA persis dipakai/dibaca `login()`/
/// `register()` biasa juga, karena semuanya satu ruang identitas Firebase
/// Auth (uid Google Sign-In == uid Firebase Auth, `FirebaseGoogleAuthService`
/// udah nuker credential Google jadi sesi Firebase Auth beneran).
///
/// **Keterbatasan JUJUR dibanding Mock (karena backend-nya sekarang
/// BENERAN, bukan disimulasiin bebas):**
/// - `login()`/`requestPasswordReset()` CUMA terima email sebagai
///   `identifier`, BUKAN nomor HP — Firebase Authentication (email/password
///   provider) nggak punya konsep "login pakai nomor HP" tanpa fitur Phone
///   Auth terpisah (di luar scope malam ini). Lempar [ValidationException]
///   yang jelas kalau `identifier` bukan email, BUKAN nyoba nebak/pura-pura
///   berhasil.
/// - `resetPassword()` (langkah 2 alur "Lupa Password" self-designed) TIDAK
///   BISA langsung set password baru dari sini — Firebase Auth beneran
///   ngirim EMAIL berisi link reset (lewat `requestPasswordReset()`/langkah
///   1), user WAJIB buka link itu buat ganti password di halaman resmi
///   Firebase, bukan lewat form kedua di app ini. Lempar [ValidationException]
///   yang ngejelasin ini, BUKAN diem-diem no-op/gagal nggak jelas.
class AuthRemoteDataSourceFirebase implements AuthRemoteDataSource {
  AuthRemoteDataSourceFirebase({
    required FirebaseGoogleAuthService googleAuthService,
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _googleAuthService = googleAuthService,
        _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseGoogleAuthService _googleAuthService;
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _wallets => _firestore.collection('wallets');

  bool _looksLikeEmail(String value) => value.trim().contains('@');

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    if (!_looksLikeEmail(identifier)) {
      throw const ValidationException(
        'Backend Firebase cuma dukung login pakai Email (bukan No. HP) — coba login pakai email ya.',
      );
    }
    try {
      final credential = await withNetworkRetry(
        () => _auth.signInWithEmailAndPassword(email: identifier.trim(), password: password),
      );
      final user = await _fetchUserProfile(credential.user!.uid);
      return _sessionFor(user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<GoogleSignInStart> loginWithGoogle() async {
    final googleResult = await _googleAuthService.signIn();
    if (googleResult == null) {
      throw const AuthException('Login Google dibatalkan.');
    }
    try {
      final doc = await withNetworkRetry(() => _users.doc(googleResult.uid).get());
      if (doc.exists) {
        final user = UserModel.fromJson({...doc.data()!, 'id': doc.id});
        return GoogleSignInStart.loggedIn(_sessionFor(user));
      }
      return GoogleSignInStart.needsRoleSelection(
        googleId: googleResult.uid,
        email: googleResult.email,
        name: googleResult.name,
      );
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<AuthSession> completeGoogleRegistration({
    required String googleId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    try {
      final user = UserModel(
        id: googleId,
        name: name,
        email: email,
        phone: '',
        role: role,
        institution: role == UserRole.peneliti ? 'Universitas Indonesia' : '',
      );
      await withNetworkRetry(() => _createUserDocuments(uid: googleId, user: user));
      return _sessionFor(user);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    final resolvedRole = UserRoleX.fromApiValue(role);
    try {
      final credential = await withNetworkRetry(
        () => _auth.createUserWithEmailAndPassword(email: email.trim(), password: password),
      );
      final uid = credential.user!.uid;
      // Best-effort — nama tampilan di Firebase Auth cuma kosmetik (mis.
      // kepake pas ada UI dari Firebase sendiri), profil "resmi" tetap di
      // Firestore. Gagal di sini nggak boleh sampai gagalin register-nya.
      try {
        await credential.user!.updateDisplayName(name);
      } catch (_) {}

      final user = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        role: resolvedRole,
        institution: resolvedRole == UserRole.peneliti ? 'Universitas Indonesia' : '',
      );
      await withNetworkRetry(() => _createUserDocuments(uid: uid, user: user));
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  /// Dipakai [register]/[completeGoogleRegistration] — 1 batch atomik biar
  /// dokumen `users/{uid}` (profil) DAN `wallets/{uid}` (saldo awal `0`,
  /// CPMK 4/5 Wallet) selalu kebentuk BARENGAN, nggak ada kondisi akun ada
  /// tapi wallet-nya nggak ada (atau sebaliknya).
  Future<void> _createUserDocuments({required String uid, required UserModel user}) async {
    final batch = _firestore.batch();
    batch.set(_users.doc(uid), user.toJson());
    batch.set(_wallets.doc(uid), {'balance': 0});
    await batch.commit();
  }

  Future<UserModel> _fetchUserProfile(String uid) async {
    final doc = await withNetworkRetry(() => _users.doc(uid).get());
    if (!doc.exists) {
      throw const ServerException(
        'Akun ketemu di Firebase Authentication tapi profilnya nggak ada di Firestore (users/{uid}).',
      );
    }
    return UserModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// `accessToken`/`refreshToken` placeholder — Firebase Auth ngatur token
  /// sesi beneran secara internal (nggak perlu di-manage manual kayak Dio
  /// JWT), pola PERSIS sama kayak yang udah dipakai "Masuk dengan Google"
  /// sebelumnya (`'firebase-$uid'`) — cuma buat ngisi bentuk [AuthSession]
  /// yang tetap dipakai `AuthLocalDataSource` (Secure Storage) biar
  /// `AuthNotifier.checkAuthStatus()` (auto-login splash) nggak perlu
  /// berubah sama sekali.
  AuthSession _sessionFor(UserModel user) {
    return AuthSession(user: user, accessToken: 'firebase-${user.id}', refreshToken: 'firebase-${user.id}');
  }

  @override
  Future<void> logout() async {
    // No-op SENGAJA — `AuthRepositoryImpl.logout()` udah manggil
    // `FirebaseGoogleAuthService.signOut()` secara terpusat (yang di
    // dalamnya JUGA manggil `FirebaseAuth.instance.signOut()`) buat SEMUA
    // datasource, terlepas login-nya lewat email/password ATAU Google.
    // Manggil `_auth.signOut()` lagi di sini cuma bakal redundan (aman/
    // idempotent, tapi nggak nambah apa-apa).
  }

  @override
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan login ulang.');
    }
    try {
      final credential = fb.EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await withNetworkRetry(() => user.reauthenticateWithCredential(credential));
      await withNetworkRetry(() => user.updatePassword(newPassword));
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e, passwordContext: true);
    }
  }

  @override
  Future<void> requestPasswordReset({required String identifier}) async {
    if (!_looksLikeEmail(identifier)) {
      throw const ValidationException(
        'Backend Firebase cuma dukung reset password lewat Email (bukan No. HP).',
      );
    }
    try {
      await withNetworkRetry(() => _auth.sendPasswordResetEmail(email: identifier.trim()));
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> resetPassword({required String identifier, required String newPassword}) async {
    // Lihat catatan "Keterbatasan JUJUR" di dokumentasi class ini —
    // Firebase Auth beneran WAJIB lewat link di email (dikirim
    // `requestPasswordReset`), nggak ada API buat "set password baru
    // langsung by identifier" dari client (itu justru lubang keamanan kalau
    // ada). Bukan bug — desain 2-langkah self-designed di UI app ini emang
    // ngasumsiin backend mock yang bebas, nggak match cara kerja backend
    // beneran.
    throw const ValidationException(
      'Cek email kamu — buka link reset password yang dikirim Firebase buat ganti password. '
      'Form ini nggak bisa langsung set password baru (beda dari mode simulasi sebelumnya).',
    );
  }

  @override
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan login ulang.');
    }
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      throw const ValidationException('Nama dan nomor HP wajib diisi.');
    }
    try {
      // Cuma update field yang BOLEH diedit dari form ini — id/email/role
      // SENGAJA nggak disentuh (sama alasan kayak `AuthRemoteDataSourceMock`
      // di catatan lengkapnya: `AuthRepositoryImpl.updateProfile` yang
      // gabungin balik id/email/role dari cache lokal, bukan dari sini).
      await withNetworkRetry(
        () => _users.doc(uid).update({
          'name': name,
          'phone': phone,
          'institution': institution,
          'academicRole': academicRole,
          'researchField': researchField,
          'gender': gender,
          'birthDate': birthDate,
          'respondentStatus': respondentStatus,
          'domicile': domicile,
          'education': education,
          'fieldOfWork': fieldOfWork,
        }),
      );
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
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Exception _mapAuthException(fb.FirebaseAuthException e, {bool passwordContext = false}) {
    switch (e.code) {
      case 'email-already-in-use':
        return const ValidationException('Email sudah terdaftar. Coba email lain.');
      case 'weak-password':
        return const ValidationException('Password terlalu lemah (minimal 6 karakter).');
      case 'invalid-email':
        return const ValidationException('Format email tidak valid.');
      case 'user-not-found':
        return const ValidationException('Email/No. HP tidak terdaftar di SurvMarkt.');
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException(passwordContext ? 'Password lama salah.' : 'Email/No. HP atau password salah.');
      case 'too-many-requests':
        return const AuthException('Terlalu banyak percobaan. Coba lagi beberapa saat lagi.');
      case 'requires-recent-login':
        return const AuthException('Sesi login sudah terlalu lama — logout lalu login ulang dulu.');
      case 'network-request-failed':
        return const NetworkException();
      default:
        return ServerException(e.message ?? 'Terjadi kesalahan Firebase Authentication.');
    }
  }

  Exception _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return const NetworkException('Koneksi ke server bermasalah. Coba lagi.');
      case 'permission-denied':
        return const ServerException('Akses ditolak — cek Firestore Security Rules.');
      default:
        return ServerException(e.message ?? 'Terjadi kesalahan Firestore.');
    }
  }
}
