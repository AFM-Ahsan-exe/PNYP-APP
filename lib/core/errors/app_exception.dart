import 'package:firebase_auth/firebase_auth.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({required this.message, this.code, this.originalError});

  factory AppException.fromFirebaseAuth(FirebaseAuthException e) {
    return AppException(
      message: _friendlyMessage(e.code),
      code: e.code,
      originalError: e,
    );
  }

  factory AppException.fromFirebaseFunctions(Object e) {
    final message = e.toString().replaceFirst(RegExp(r'^.+?: '), '');
    return AppException(
      message: message.isNotEmpty ? message : 'An unexpected error occurred',
      originalError: e,
    );
  }

  factory AppException.network() {
    return const AppException(
      message: 'Network error. Check your internet connection and try again.',
    );
  }

  factory AppException.unexpected() {
    return const AppException(
      message: 'Something went wrong. Please try again.',
    );
  }

  @override
  String toString() => message;
}

String _friendlyMessage(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Invalid email or password. Please try again.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait and try again later.';
    case 'network-request-failed':
      return 'Network error. Check your internet connection.';
    case 'user-not-verified':
      return 'Please verify your email address before continuing.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
