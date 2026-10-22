import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';

/// An error carrying a user-friendly message from [AppStrings].
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  /// Maps any thrown object to an [AppException] with friendly text.
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is TimeoutException) return const AppException(AppStrings.errorTimeout, code: 'timeout');
    if (error is FirebaseAuthException) return AppException(_auth(error.code), code: error.code);
    if (error is FirebaseException) return AppException(_firestore(error.code), code: error.code);
    // Some plugin calls (e.g. aggregation queries on Android) surface as a raw
    // PlatformException with the Firestore code inside `details`.
    if (error is PlatformException) {
      final details = error.details;
      final code = details is Map ? details['code']?.toString() : null;
      if (code != null) return AppException(_firestore(code), code: code);
    }
    debugPrint('Unmapped error: $error');
    return const AppException(AppStrings.errorGeneric);
  }

  static String _auth(String code) => switch (code) {
    'email-already-in-use' => AppStrings.errorEmailInUse,
    'invalid-email' => AppStrings.invalidEmail,
    'wrong-password' || 'invalid-credential' || 'INVALID_LOGIN_CREDENTIALS' => AppStrings.errorInvalidCredentials,
    'user-not-found' => AppStrings.errorUserNotFound,
    'user-disabled' => AppStrings.errorUserDisabled,
    'weak-password' => AppStrings.errorWeakPassword,
    'too-many-requests' => AppStrings.errorTooManyRequests,
    'network-request-failed' => AppStrings.errorNetwork,
    _ => AppStrings.errorGeneric,
  };

  static String _firestore(String code) => switch (code) {
    'permission-denied' => AppStrings.errorPermission,
    'not-found' => AppStrings.errorNotFound,
    'unavailable' => AppStrings.errorUnavailable,
    'deadline-exceeded' => AppStrings.errorTimeout,
    'already-exists' => AppStrings.errorPermission,
    _ => AppStrings.errorGeneric,
  };

  @override
  String toString() => 'AppException($code): $message';
}
