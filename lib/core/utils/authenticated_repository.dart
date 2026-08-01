import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when a Supabase call fails due to network or timeout.
class RepositoryException implements Exception {
  final String message;
  final Object? cause;
  RepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'RepositoryException: $message';
}

mixin AuthenticatedRepository {
  SupabaseClient get client;

  /// Default timeout for all Supabase calls.
  static const Duration defaultTimeout = Duration(seconds: 10);

  String get currentUserId {
    final user = client.auth.currentUser;
    if (user == null) {
      throw AuthException('Session expired. Please sign in again.');
    }
    return user.id;
  }

  /// Wraps a Supabase call with timeout and error handling.
  ///
  /// Catches [SocketException], [TimeoutException], [AuthException],
  /// and [PostgrestException], rethrowing as [RepositoryException]
  /// with a user-friendly message.
  Future<T> safeCall<T>(
    Future<T> Function() call, {
    Duration timeout = defaultTimeout,
  }) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      debugPrint('Supabase call timed out after ${timeout.inSeconds}s');
      throw RepositoryException(
        'Request timed out. Please check your connection and try again.',
      );
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      throw RepositoryException(
        'No internet connection. Please check your network and try again.',
        e,
      );
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      throw RepositoryException(
        'Session expired. Please sign in again.',
        e,
      );
    } on PostgrestException catch (e) {
      debugPrint('Database error: ${e.message}');
      throw RepositoryException(
        'Something went wrong. Please try again.',
        e,
      );
    }
  }
}
