import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../../core/error/exceptions.dart';

class FirebaseAuthSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirebaseAuthSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code}');
      throw AuthenticationException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      _logger.e('Sign in error: $e');
      throw AuthenticationException(message: e.toString());
    }
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code}');
      throw AuthenticationException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      _logger.e('Sign up error: $e');
      throw AuthenticationException(message: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logger.e('Sign out error: $e');
      throw AuthenticationException(message: e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(message: e.toString());
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(message: 'No user logged in');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(message: e.toString());
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(message: 'No user logged in');
      }
      await user.updateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(message: e.toString());
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(message: 'No user logged in');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(message: e.toString());
    }
  }

  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(message: 'No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthenticationException(message: e.toString());
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthenticationException(message: 'No user logged in');
      }
      await user.sendEmailVerification();
    } catch (e) {
      throw AuthenticationException(message: e.toString());
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      case 'requires-recent-login':
        return 'Please login again to continue';
      default:
        return 'Authentication error: $code';
    }
  }
}