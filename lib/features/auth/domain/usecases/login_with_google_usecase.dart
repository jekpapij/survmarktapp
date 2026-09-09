import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/google_signin_outcome.dart';
import '../repositories/auth_repository.dart';

/// "Masuk dengan Google" — Google Sign-In BENERAN via Firebase (lihat
/// catatan lengkap di `FirebaseGoogleAuthService`/
/// `AuthRemoteDataSourceMock.loginWithGoogle`). `NoParams` karena beda dari
/// `LoginUseCase`, nggak ada input dari user sama sekali (nggak ada
/// email/password yang diketik).
///
/// Update (pertanyaan user — "kok akun Google baru selalu Responden?"):
/// balikin [GoogleSignInOutcome] (bisa `loggedIn` ATAU
/// `needsRoleSelection`), BUKAN langsung `UserEntity` lagi — lihat
/// `CompleteGoogleRegistrationUseCase` buat langkah finalisasi akun BARU.
class LoginWithGoogleUseCase implements UseCase<GoogleSignInOutcome, NoParams> {
  const LoginWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, GoogleSignInOutcome>> call(NoParams params) {
    return _repository.loginWithGoogle();
  }
}
