import 'package:equatable/equatable.dart';

/// Failure — dipakai di layer domain/presentation (lihat PROMPT_SPEC.md §2.4).
/// Repository selalu mengembalikan `Either<Failure, T>`, tidak pernah
/// melempar exception mentah ke atas.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi masalah pada server. Coba lagi nanti.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Email/No. HP atau password salah.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal membaca data lokal.']);
}
