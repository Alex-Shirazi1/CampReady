// FirebaseBackend timeout tests.
//
// Regression test for the Nov 5, 2026 hang: on web,
// Firebase.initializeApp() dynamically imports the Firebase JS SDK
// from gstatic. If that import never resolves, the Future never
// completes, main() never reaches runApp, and the app hangs blank
// instead of falling back to local mode. FirebaseBackend.initialize()
// must time out and report false instead of hanging forever.
// These tests inject a never-completing / failing initializer so no
// real Firebase project or network is involved.
import 'dart:async';

import 'package:campready/services/backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseBackend.initialize timeout', () {
    tearDown(() {
      FirebaseBackend.configured = false;
    });

    test(
      'a never-completing initializer returns false within the timeout',
      () async {
        final stopwatch = Stopwatch()..start();
        final result = await FirebaseBackend.initialize(
          initializer: () => Completer<void>().future,
          timeout: const Duration(milliseconds: 200),
        );
        stopwatch.stop();
        expect(result, isFalse);
        expect(FirebaseBackend.configured, isFalse);
        // Must have given up near the timeout, not hung forever.
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
      },
    );

    test('a failing initializer returns false', () async {
      final result = await FirebaseBackend.initialize(
        initializer: () async => throw StateError('no network'),
        timeout: const Duration(seconds: 5),
      );
      expect(result, isFalse);
      expect(FirebaseBackend.configured, isFalse);
    });

    test('a completing initializer returns true', () async {
      final result = await FirebaseBackend.initialize(
        initializer: () async {},
        timeout: const Duration(seconds: 5),
      );
      expect(result, isTrue);
      expect(FirebaseBackend.configured, isTrue);
    });
  });
}
