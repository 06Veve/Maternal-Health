import 'package:firebase_auth/firebase_auth.dart';
import 'package:bebezen/services/logger.dart';

/// Authentication service for managing Firebase Auth operations
/// Provides email/password authentication with proper error handling
class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _tag = 'AuthService';

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  /// Throws FirebaseAuthException on auth errors
  /// Throws general Exception on unexpected errors
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info(
        'Signing in user: $email',
        tag: _tag,
      );

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      AppLogger.success(
        'User signed in: ${credential.user?.email}',
        tag: _tag,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'Firebase auth error: ${e.code}',
        tag: _tag,
        exception: e.message,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        'Unexpected sign-in error',
        tag: _tag,
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Create new user with email and password
  /// Throws FirebaseAuthException on auth errors
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info(
        'Creating user account: $email',
        tag: _tag,
      );

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      AppLogger.success(
        'User account created: ${credential.user?.email}',
        tag: _tag,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'Firebase auth error during signup: ${e.code}',
        tag: _tag,
        exception: e.message,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        'Unexpected signup error',
        tag: _tag,
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.info(
        'Sending password reset email to: $email',
        tag: _tag,
      );

      await _auth.sendPasswordResetEmail(email: email.trim());

      AppLogger.success(
        'Password reset email sent',
        tag: _tag,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'Error sending reset email: ${e.code}',
        tag: _tag,
        exception: e.message,
      );
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      AppLogger.info(
        'Signing out user',
        tag: _tag,
      );

      await _auth.signOut();

      AppLogger.success(
        'User signed out',
        tag: _tag,
      );
    } catch (e, st) {
      AppLogger.error(
        'Error during sign out',
        tag: _tag,
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No user logged in');
      }

      await _auth.currentUser!.updateDisplayName(displayName);

      AppLogger.info(
        'Display name updated to: $displayName',
        tag: _tag,
      );
    } catch (e, st) {
      AppLogger.error(
        'Error updating display name',
        tag: _tag,
        exception: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}