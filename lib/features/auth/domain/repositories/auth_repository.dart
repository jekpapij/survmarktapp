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
}
