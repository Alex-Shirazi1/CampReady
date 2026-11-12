import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const bool kFirebaseOptionsConfigured = true;

/// Client config for campready-group2, from `flutterfire configure`.
/// These keys are public app identifiers, not secrets.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqUGv8lzaFWEG8jrOSo9yM6EoWLW8nlKY',
    appId: '1:555369541366:web:74ac3b724d0c9a46fe46d7',
    messagingSenderId: '555369541366',
    projectId: 'campready-group2',
    authDomain: 'campready-group2.firebaseapp.com',
    storageBucket: 'campready-group2.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBu1lUFGJ8PZDyGyNZljA9U0AsOBFXGR9Y',
    appId: '1:555369541366:android:1876438574182118fe46d7',
    messagingSenderId: '555369541366',
    projectId: 'campready-group2',
    storageBucket: 'campready-group2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-fKHBjIaSBoKm-xY2keOctVMtM3Qtv2Q',
    appId: '1:555369541366:ios:f2f9776f2c9c29fffe46d7',
    messagingSenderId: '555369541366',
    projectId: 'campready-group2',
    storageBucket: 'campready-group2.firebasestorage.app',
    iosBundleId: 'com.campready.campready',
  );
}
