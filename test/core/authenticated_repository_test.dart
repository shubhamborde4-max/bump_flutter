import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bump/core/utils/authenticated_repository.dart';

/// Concrete test class that uses the safeCall mixin.
class _TestRepository with AuthenticatedRepository {
  @override
  SupabaseClient get client => throw UnimplementedError();
}

void main() {
  late _TestRepository repo;

  setUp(() {
    repo = _TestRepository();
  });

  group('safeCall', () {
    test('returns the result of a successful call', () async {
      final result = await repo.safeCall(() async => 42);
      expect(result, 42);
    });

    test('throws RepositoryException on TimeoutException', () async {
      expect(
        () => repo.safeCall(
          () => Future.delayed(const Duration(seconds: 30), () => 42),
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<RepositoryException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        )),
      );
    });

    test('throws RepositoryException on SocketException', () async {
      expect(
        () => repo.safeCall(
          () async => throw const SocketException('No route to host'),
        ),
        throwsA(isA<RepositoryException>().having(
          (e) => e.message,
          'message',
          contains('No internet'),
        )),
      );
    });

    test('preserves the original exception as cause', () async {
      final original = const SocketException('Connection refused');
      try {
        await repo.safeCall(() async => throw original);
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.cause, original);
      }
    });

    test('passes through non-handled exceptions', () async {
      expect(
        () => repo.safeCall(
          () async => throw StateError('unexpected'),
        ),
        throwsStateError,
      );
    });
  });
}
