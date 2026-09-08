import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Kontrak repository auth — implementasi konkretnya di layer data
/// (lihat data/repositories/auth_repository_impl.dart). Domain layer di sini
/// murni Dart, zero Flutter dependency — PROMPT_SPEC.md §2.2.
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String identifier,
    required String password,
  });

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
  Future<Either<Failure, UserEntity>> updateProfile({
    required String name,
    required String phone,
    required String institution,
    required String academicRole,
    required String researchField,
  });
}
