// Firebase configuration for CampReady (CSEN 268, Group 2).
//
// Real project, created Nov 5, 2026 under alexxshirazi@gmail.com
// (Alex Shirazi, sole Owner), Spark plan — $0/month, no billing
// account, no payment info, Analytics off.
//   Project: CampReady
//   Project ID: campready-group2
//   Project number: 555369541366
//   Web app: 'CampReady Web'
//   App ID: 1:555369541366:web:74ac3b724d0c9a46fe46d7
//
// These are client-side Firebase config values (the same values the
// Firebase Console shows on the web-app settings page and the same
// values `flutterfire configure` would generate). They are not
// server secrets — Firebase security comes from Auth + Firestore
// rules, not from hiding these values. Do not add any server/service-
// account keys here.
//
// Only the Web app is registered in the console so far (no Android /
// iOS app yet), so the web config below is returned for every
// platform. That lets Firebase.initializeApp() run on any platform;
// register native apps in the console and re-run
// `flutterfire configure` if per-platform options are needed later.
//
// If Firebase init fails for any reason, CampReadyServices falls
// back to local mode (in-memory Auth/Firestore/messaging), so the
// app never crashes on a missing network or misconfiguration.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        // No native app registered yet; reuse the web config.
        return web;
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
}
