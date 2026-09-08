import 'package:equatable/equatable.dart';

/// Tiga role SurvMarkt yang bisa register sendiri (Peneliti/Responden) +
/// Admin (dibuat manual, bukan lewat register-page — lihat CLAUDE.md
/// "Keputusan produk penting"). Dropdown "Daftar Sebagai" di register-page
/// cuma nampilin peneliti & responden.
enum UserRole { peneliti, responden, admin }

extension UserRoleX on UserRole {
  /// Label yang ditampilkan di UI (dropdown, profil, dsb).
  String get label => switch (this) {
        UserRole.peneliti => 'Peneliti',
        UserRole.responden => 'Responden',
        UserRole.admin => 'Admin',
      };

  /// Value yang dikirim ke/diterima dari API — backend (kerjaan Ammar) pakai
  /// istilah Inggris researcher/respondent/admin di field `role`.
  String get apiValue => switch (this) {
        UserRole.peneliti => 'researcher',
        UserRole.responden => 'respondent',
        UserRole.admin => 'admin',
      };

  static UserRole fromApiValue(String value) => switch (value.toLowerCase()) {
        'peneliti' || 'researcher' => UserRole.peneliti,
        'responden' || 'respondent' => UserRole.responden,
        'admin' => UserRole.admin,
        _ => throw ArgumentError('Role tidak dikenal dari API: $value'),
      };
}

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.institution = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  // Update 2026-09-08: field baru buat card "Informasi Akun" di frame Figma
  // `researcher-profile` (node 77:2331) — default '' (bukan required) biar
  // nggak perlu ubah tempat lain yang udah bikin UserEntity/UserModel (login/
  // register mock). Register-page emang nggak ada field ini (form Figma-nya
  // cuma nama/HP/email/password), jadi user baru dari register selalu ''
  // sampai ada fitur "Edit Profil" yang bisa isi/ubah field ini.
  final String institution;

  @override
  List<Object?> get props => [id, name, email, phone, role, institution];
}
