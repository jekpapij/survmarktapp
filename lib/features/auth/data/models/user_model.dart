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
      };
}
