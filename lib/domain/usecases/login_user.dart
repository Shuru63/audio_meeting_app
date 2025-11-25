import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class LoginUserUseCase {
  final AuthRepository repository;

  LoginUserUseCase(this.repository);

  Future<Either<Failure, UserModel>> call({
    required String email,
    required String password,
    String? deviceId,
  }) async {
    // Validate inputs
    if (email.isEmpty) {
      return Left(ValidationFailure('Email cannot be empty'));
    }

    if (password.isEmpty) {
      return Left(ValidationFailure('Password cannot be empty'));
    }

    if (!_isValidEmail(email)) {
      return Left(ValidationFailure('Invalid email format'));
    }

    if (password.length < 6) {
      return Left(ValidationFailure('Password must be at least 6 characters'));
    }

    // Call repository
    return await repository.login(
      email: email,
      password: password,
      deviceId: deviceId,
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}