class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({
    this.message = 'Network connection failed',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException({
    this.message = 'Cache operation failed',
  });

  @override
  String toString() => 'CacheException: $message';
}

class AuthenticationException implements Exception {
  final String message;
  final String? code;

  AuthenticationException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthenticationException: $message (Code: $code)';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  ValidationException({
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException implements Exception {
  final String message;
  final String? permission;

  PermissionException({
    required this.message,
    this.permission,
  });

  @override
  String toString() => 'PermissionException: $message (Permission: $permission)';
}

class FirebaseException implements Exception {
  final String message;
  final String? code;

  FirebaseException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'FirebaseException: $message (Code: $code)';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException({
    this.message = 'Request timeout',
  });

  @override
  String toString() => 'TimeoutException: $message';
}

class NotFoundException implements Exception {
  final String message;
  final String? resource;

  NotFoundException({
    required this.message,
    this.resource,
  });

  @override
  String toString() => 'NotFoundException: $message (Resource: $resource)';
}

class ConflictException implements Exception {
  final String message;

  ConflictException({
    required this.message,
  });

  @override
  String toString() => 'ConflictException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({
    this.message = 'Unauthorized access',
  });

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;

  ForbiddenException({
    this.message = 'Access forbidden',
  });

  @override
  String toString() => 'ForbiddenException: $message';
}

class BadRequestException implements Exception {
  final String message;

  BadRequestException({
    required this.message,
  });

  @override
  String toString() => 'BadRequestException: $message';
}

class InternalServerException implements Exception {
  final String message;

  InternalServerException({
    this.message = 'Internal server error',
  });

  @override
  String toString() => 'InternalServerException: $message';
}