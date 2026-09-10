import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Finalisasi akun Google BARU — dipanggil dari `LoginScreen` SETELAH
/// `LoginWithGoogleUseCase` balikin `GoogleSignInOutcome.needsRoleSelection`
/// DAN user udah milih role di dialog. Lihat catatan lengkap di
/// `GoogleSignInOutcome`/`AuthRepository.completeGoogleRegistration`.
class CompleteGoogleRegistrationParams extends Equatable {
  const CompleteGoogleRegistrationParams({
    required this.googleId,
    required this.email,
    required this.name,
    required this.role,
  });

  final String googleId;
  final String email;
  final String name;
  final UserRole role;

  @override
  List<Object?> get props => [googleId, email, name, role];
}

class CompleteGoogleRegistrationUseCase
    implements UseCase<UserEntity, CompleteGoogleRegistrationParams> {
  const CompleteGoogleRegistrationUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(CompleteGoogleRegistrationParams params) {
    return _repository.completeGoogleRegistration(
      googleId: params.googleId,
      email: params.email,
      name: params.name,
      role: params.role,
    );
  }
}
