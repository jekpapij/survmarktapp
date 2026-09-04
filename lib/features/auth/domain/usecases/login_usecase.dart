import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.identifier, required this.password});

  /// Email ATAU no. HP — LoginScreen pakai satu field buat dua-duanya
  /// (lihat frame `login-page` di Figma: "email/no HP + password").
  final String identifier;
  final String password;

  @override
  List<Object?> get props => [identifier, password];
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) {
    return _repository.login(identifier: params.identifier, password: params.password);
  }
}
