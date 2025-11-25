import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/error/failure.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseService _firebaseService;

  UserRepository(this._firebaseService);

  Future<Either<Failure, UserModel>> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return Left(Failure('Failed to create user'));
      }

      // Create user document
      final user = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firebaseService.setDocument(
        collection: 'users',
        docId: user.id,
        data: user.toFirestore(),
      );

      return Right(user);
    } catch (e) {
      return Left(Failure('Failed to create user: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? role,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role;
      if (isActive != null) updates['isActive'] = isActive;

      if (updates.isEmpty) {
        return Left(Failure('No updates provided'));
      }

      await _firebaseService.updateDocument(
        collection: 'users',
        docId: userId,
        data: updates,
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to update user: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firebaseService.deleteDocument('users', userId);

      // Delete Firebase Auth user (requires admin SDK in production)
      // For now, just deactivate
      await _firebaseService.updateDocument(
        collection: 'users',
        docId: userId,
        data: {'isActive': false},
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to delete user: ${e.toString()}'));
    }
  }

  Future<Either<Failure, UserModel>> getUser(String userId) async {
    try {
      final doc = await _firebaseService.getDocument('users', userId);

      if (!doc.exists) {
        return Left(Failure('User not found'));
      }

      return Right(UserModel.fromFirestore(doc));
    } catch (e) {
      return Left(Failure('Failed to get user: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<UserModel>>> getAllUsers() async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      return Right(users);
    } catch (e) {
      return Left(Failure('Failed to get users: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<UserModel>>> getActiveUsers() async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      return Right(users);
    } catch (e) {
      return Left(Failure('Failed to get active users: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      // This requires admin SDK in production
      // For now, send password reset email
      final userDoc = await _firebaseService.getDocument('users', userId);
      if (!userDoc.exists) {
        return Left(Failure('User not found'));
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final email = userData['email'];

      await _firebaseService.auth.sendPasswordResetEmail(email: email);

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to reset password: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> activateUser(String userId) async {
    return updateUser(userId: userId, isActive: true);
  }

  Future<Either<Failure, void>> deactivateUser(String userId) async {
    return updateUser(userId: userId, isActive: false);
  }

  Future<Either<Failure, void>> forceLogout(String userId) async {
    try {
      await _firebaseService.updateDocument(
        collection: 'users',
        docId: userId,
        data: {
          'deviceId': null,
          'fcmToken': null,
        },
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to force logout: ${e.toString()}'));
    }
  }

  Stream<UserModel> userStream(String userId) {
    return _firebaseService
        .documentStream('users', userId)
        .map((snapshot) => UserModel.fromFirestore(snapshot));
  }

  Stream<List<UserModel>> usersStream() {
    return _firebaseService.firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }
}