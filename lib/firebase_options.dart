import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

/// True: real options are present for the CampReady project.
const bool kFirebaseOptionsConfigured = true;

/// Generated-style options for the CampReady project
/// (campready-group2). Hand-written from the Firebase Console
/// web-app config, in the format `flutterfire configure` produces.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'Firebase is not configured for $defaultTargetPlatform. '
      'Register this platform and run flutterfire configure.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqUGv8lzaFWEG8jrOSo9yM6EoWLW8nlKY',
    appId: '1:555369541366:web:74ac3b724d0c9a46fe46d7',
    messagingSenderId: '555369541366',
    projectId: 'campready-group2',
    authDomain: 'campready-group2.firebaseapp.com',
    storageBucket: 'campready-group2.firebasestorage.app',
  );
}
