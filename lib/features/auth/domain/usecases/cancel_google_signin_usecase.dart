import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Dipanggil dari `LoginScreen` kalau user BATAL di dialog pilih role
/// (`_GooglePickRoleDialog`) abis `LoginWithGoogleUseCase` balikin
/// `GoogleSignInOutcome.needsRoleSelection` — lihat catatan lengkap di
/// `AuthRepository.cancelGoogleSignIn`.
class CancelGoogleSignInUseCase implements UseCase<void, NoParams> {
  const CancelGoogleSignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.cancelGoogleSignIn();
  }
}
