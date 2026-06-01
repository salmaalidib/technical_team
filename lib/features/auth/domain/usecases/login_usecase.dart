import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/login_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, LoginResponse>> call({
    required String userName,
    required String password,
  }) {
    return repository.login(userName: userName, password: password);
  }
}
