import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(UserEntity authUser)
      : this(status: AuthStatus.authenticated, user: authUser);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.error(String message) : this(status: AuthStatus.error, errorMessage: message);

  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
