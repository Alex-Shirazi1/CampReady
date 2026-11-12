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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
