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
    this.academicRole = '',
    this.researchField = '',
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

  // Update 2026-09-08: 2 field baru buat card "Afiliasi" di frame Figma
  // `researcher-profile-edit` (node 77:2654). PENTING — "Peran" di frame
  // ini BUKAN `UserRole` (peneliti/responden/admin, yang nentuin
  // dashboard/routing) — itu udah kepake di tempat lain & nggak masuk akal
  // diubah bebas dari form ini. Dibaca sebagai status akademik/profesional
  // TAMBAHAN di dalam institusi (mis. "Dosen"/"Mahasiswa"/"Peneliti
  // Independen") — konsep baru, disimpan terpisah sebagai `academicRole`
  // (String bebas, bukan enum, pola sama kayak dropdown targeting di
  // `create-survey`). `researchField` = "Bidang Penelitian / Jurusan",
  // opsional (nggak ada tanda `*` di Figma).
  final String academicRole;
  final String researchField;

  UserEntity copyWith({
    String? name,
    String? phone,
    String? institution,
    String? academicRole,
    String? researchField,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      institution: institution ?? this.institution,
      academicRole: academicRole ?? this.academicRole,
      researchField: researchField ?? this.researchField,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, email, phone, role, institution, academicRole, researchField];
}
