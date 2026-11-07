import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBackend {
  static bool configured = false;

  static const Duration initializeTimeout = Duration(seconds: 10);

  static Future<bool> initialize({
    Future<void> Function()? initializer,
    Duration timeout = initializeTimeout,
  }) async {
    if (!kFirebaseOptionsConfigured) return false;
    try {
      await (initializer ?? _defaultInitializer)().timeout(timeout);
      configured = true;
      return true;
    } catch (_) {
      configured = false;
      return false;
    }
  }

  static Future<void> _defaultInitializer() async {
    const emulator = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    await Firebase.initializeApp(
      options: emulator
          ? const FirebaseOptions(
              apiKey: 'demo-api-key',
              appId: '1:123456789:web:demo',
              messagingSenderId: '123456789',
              projectId: 'demo-campready',
            )
          : DefaultFirebaseOptions.currentPlatform,
    );
  }
}
