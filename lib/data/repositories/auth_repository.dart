import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/error/failure.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseService _firebaseService;

  AuthRepository(this._firebaseService);

  Future<Either<Failure, UserModel>> login({
    required String email,
    required String password,
    String? deviceId,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return Left(Failure('Login failed'));
      }

      // Get user document
      final userDoc = await _firebaseService.getDocument(
        'users',
        userCredential.user!.uid,
      );

      if (!userDoc.exists) {
        await _firebaseService.signOut();
        return Left(Failure('User account not found'));
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Check if account is active
      if (userData['isActive'] == false) {
        await _firebaseService.signOut();
        return Left(Failure('Your account is inactive. Please contact admin.'));
      }

      // Check device ID for single device login
      final storedDeviceId = userData['deviceId'];
      if (storedDeviceId != null && 
          storedDeviceId.isNotEmpty && 
          storedDeviceId != deviceId) {
        // Force logout from old device by updating device ID
        await _firebaseService.updateDocument(
          collection: 'users',
          docId: userCredential.user!.uid,
          data: {
            'deviceId': deviceId,
            'lastLogin': FieldValue.serverTimestamp(),
          },
        );
      } else if (deviceId != null) {
        // Update device ID if not set
        await _firebaseService.updateDocument(
          collection: 'users',
          docId: userCredential.user!.uid,
          data: {
            'deviceId': deviceId,
            'lastLogin': FieldValue.serverTimestamp(),
          },
        );
      }

      // Get and update FCM token
      final fcmToken = await _firebaseService.getFCMToken();
      if (fcmToken != null) {
        await _firebaseService.updateDocument(
          collection: 'users',
          docId: userCredential.user!.uid,
          data: {'fcmToken': fcmToken},
        );
      }

      // Create user model
      final user = UserModel.fromJson({
        ...userData,
        'id': userCredential.user!.uid,
      });

      return Right(user);
    } catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    }
  }

  Future<Either<Failure, void>> logout() async {
    try {
      final currentUser = _firebaseService.getCurrentUser();
      
      if (currentUser != null) {
        // Clear device ID and FCM token
        await _firebaseService.updateDocument(
          collection: 'users',
          docId: currentUser.uid,
          data: {
            'deviceId': null,
            'fcmToken': null,
          },
        );
      }

      await _firebaseService.signOut();
      return const Right(null);
    } catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    }
  }

  Future<Either<Failure, UserModel>> getCurrentUser() async {
    try {
      final currentUser = _firebaseService.getCurrentUser();
      
      if (currentUser == null) {
        return Left(Failure('No user logged in'));
      }

      final userDoc = await _firebaseService.getDocument(
        'users',
        currentUser.uid,
      );

      if (!userDoc.exists) {
        return Left(Failure('User data not found'));
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final user = UserModel.fromJson({
        ...userData,
        'id': currentUser.uid,
      });

      return Right(user);
    } catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    }
  }

  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    }
  }

  Stream<UserModel?> authStateChanges() {
    return _firebaseService.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      try {
        final userDoc = await _firebaseService.getDocument('users', user.uid);
        if (!userDoc.exists) return null;

        final userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromJson({...userData, 'id': user.uid});
      } catch (e) {
        return null;
      }
    });
  }

  String _getErrorMessage(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (errorMessage.contains('user-disabled')) {
      return 'This account has been disabled';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later';
    } else if (errorMessage.contains('network')) {
      return 'Network error. Please check your connection';
    } else {
      return 'An error occurred. Please try again';
    }
  }
}