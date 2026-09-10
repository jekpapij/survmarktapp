import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Dipakai `AdminLoginScreen` — lihat doc-comment lengkap di
/// `AuthRepository.loginAsDummyAdmin` (bugfix 2026-09-10: admin harus tetap
/// FULL DUMMY, terlepas dari `ApiConstants.useFirebaseBackend`).
class LoginAsDummyAdminUseCase implements UseCase<UserEntity, NoParams> {
  const LoginAsDummyAdminUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return _repository.loginAsDummyAdmin();
  }
}
