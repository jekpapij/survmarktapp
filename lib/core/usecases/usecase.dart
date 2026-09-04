import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Abstract UseCase<ResultType, Params> — PROMPT_SPEC.md §2.2.
abstract class UseCase<ResultType, Params> {
  Future<Either<Failure, ResultType>> call(Params params);
}

/// Dipakai untuk usecase yang tidak butuh parameter (mis. logout, cek sesi).
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
