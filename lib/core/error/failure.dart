import 'package:equatable/equatable.dart';

abstract class FailureBase extends Equatable {
  final String message;

  const FailureBase(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class Failure extends FailureBase {
  const Failure(super.message);
}

class ServerFailure extends FailureBase {
  const ServerFailure([super.message = 'Server error occurred']);
}

class NetworkFailure extends FailureBase {
  const NetworkFailure([super.message = 'Network connection failed']);
}

class CacheFailure extends FailureBase {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class AuthenticationFailure extends FailureBase {
  const AuthenticationFailure([super.message = 'Authentication failed']);
}

class ValidationFailure extends FailureBase {
  const ValidationFailure([super.message = 'Validation failed']);
}

class PermissionFailure extends FailureBase {
  const PermissionFailure([super.message = 'Permission denied']);
}