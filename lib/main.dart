import 'package:flutter/material.dart';

import 'app.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tries Firebase and falls back to local mode (in-memory auth /
  // Firestore / messaging) when no Firebase project is configured.
  // Never throws: the app must run on web with no keys.
  final services = await CampReadyServices.initialize();
  runApp(CampReady(services: services));
}
