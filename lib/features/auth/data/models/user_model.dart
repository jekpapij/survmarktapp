import '../../domain/entities/user_entity.dart';

/// UserModel — mapping JSON <-> UserEntity. Dipisah dari entity murni per
/// aturan Clean Architecture di PROMPT_SPEC.md §2.2 (domain layer nggak boleh
/// tau soal serialisasi).
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.institution,
    super.academicRole,
    super.researchField,
    super.gender,
    super.birthDate,
    super.respondentStatus,
    super.domicile,
    super.education,
    super.fieldOfWork,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: UserRoleX.fromApiValue(json['role'] as String),
      // `?? ''` — backward-compatible sama cache lama (secure storage) dari
      // sebelum field-field ini ada, biar user yang udah login duluan
      // nggak crash pas app di-update.
      institution: json['institution'] as String? ?? '',
      academicRole: json['academicRole'] as String? ?? '',
      researchField: json['researchField'] as String? ?? '',
      // Update 2026-09-09: 4 field "Data Responden" (frame `respondent-
      // profil`, node 89:4765) — sama pola `?? ''` backward-compatible.
      gender: json['gender'] as String? ?? '',
      // Update 2026-09-09: `age` (angka statis) diganti `birthDate` (ISO
      // `yyyy-MM-dd`) — lihat catatan lengkap di `user_entity.dart`. Masih
      // baca key JSON lama `'age'` sebagai fallback KALAU `'birthDate'`
      // nggak ada (cache lokal dari sebelum perubahan ini) supaya user yang
      // udah pernah login duluan nggak crash — walau nilainya (angka umur
      // statis, bukan tanggal) nggak valid buat di-parse ulang jadi umur
      // via `Formatters.ageLabelFromBirthDate`, jadi efeknya field ini balik
      // ke "Belum diisi" sekali sampai user isi ulang lewat `respondent-
      // edit-profile` — trade-off yang wajar buat cache lama non-fatal.
      birthDate: json['birthDate'] as String? ?? '',
      respondentStatus: json['respondentStatus'] as String? ?? '',
      domicile: json['domicile'] as String? ?? '',
      education: json['education'] as String? ?? '',
      fieldOfWork: json['fieldOfWork'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.apiValue,
        'institution': institution,
        'academicRole': academicRole,
        'researchField': researchField,
        'gender': gender,
        'birthDate': birthDate,
        'respondentStatus': respondentStatus,
        'domicile': domicile,
        'education': education,
        'fieldOfWork': fieldOfWork,
      };
}
