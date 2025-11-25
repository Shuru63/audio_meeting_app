import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  bool get isHost => role == 'host' || role == 'admin';
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        isActive,
        createdAt,
        lastLogin,
      ];

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email, role: $role)';
  }
}