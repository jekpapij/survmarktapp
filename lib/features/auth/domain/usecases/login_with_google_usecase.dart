import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// "Masuk dengan Google" — SIMULASI dummy (lihat catatan lengkap di
/// `AuthRemoteDataSourceMock.loginWithGoogle`). `NoParams` karena beda dari
/// `LoginUseCase`, nggak ada input dari user sama sekali (nggak ada
/// email/password yang diketik).
class LoginWithGoogleUseCase implements UseCase<UserEntity, NoParams> {
  const LoginWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return _repository.loginWithGoogle();
  }
}
