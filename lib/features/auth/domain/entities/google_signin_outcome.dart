import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// Hasil `loginWithGoogle()` — BELUM TENTU langsung "login selesai".
///
/// Latar belakang (pertanyaan user 2026-09-09 — "kok akun Google baru
/// selalu jadi Responden?"): versi awal SELALU hardcode `role: responden`
/// buat akun Google yang belum pernah register. Diputuskan diganti: akun
/// Google BARU sekarang WAJIB milih role dulu lewat dialog di
/// `LoginScreen` sebelum akun-nya difinalisasi — entity ini yang
/// nyampein sinyal "user butuh milih role" itu dari datasource sampai ke
/// UI, TANPA numpangin status baru ke `AuthState`/`AuthStatus`
/// (state-machine Initial/Loading/Authenticated/Unauthenticated/Error
/// yang jadi bukti CPMK 3 dibiarin APA ADANYA — nggak diutak-atik).
class GoogleSignInOutcome extends Equatable {
  const GoogleSignInOutcome._({
    this.user,
    this.googleId,
    this.email,
    this.name,
  });

  /// Akun Google ini SUDAH terdaftar sebelumnya (baik lewat register email/
  /// password manual, ATAU login Google sebelumnya yang udah milih role) —
  /// login LANGSUNG SELESAI, nggak butuh dialog pilih role lagi.
  const GoogleSignInOutcome.loggedIn(UserEntity user) : this._(user: user);

  /// Akun Google ini BARU (belum pernah kedaftar sama sekali) — UI WAJIB
  /// nampilin dialog pilih role dulu, baru panggil
  /// `AuthNotifier.completeGoogleRegistration(...)` bawa role yang
  /// dipilih + 3 field identitas Google mentah di bawah ini.
  const GoogleSignInOutcome.needsRoleSelection({
    required String googleId,
    required String email,
    required String name,
  }) : this._(googleId: googleId, email: email, name: name);

  final UserEntity? user;
  final String? googleId;
  final String? email;
  final String? name;

  bool get needsRoleSelection => user == null;

  @override
  List<Object?> get props => [user, googleId, email, name];
}
