import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Dipakai SplashScreen buat cek apakah ada sesi tersimpan (auto-login),
/// biar user yang udah pernah login nggak balik ke LoginScreen tiap buka app.
class GetCurrentUserUseCase implements UseCase<UserEntity?, NoParams> {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) {
    return _repository.getCurrentUser();
  }
}
