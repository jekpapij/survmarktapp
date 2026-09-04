import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String phone;
  final String email;
  final String password;
  final UserRole role;

  @override
  List<Object?> get props => [name, phone, email, password, role];
}

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return _repository.register(
      name: params.name,
      phone: params.phone,
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}
