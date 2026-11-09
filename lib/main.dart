import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/services.dart';
import 'theme.dart';

/// Background-message handler for mobile. Must be top-level, must
/// initialise Firebase first, and must not touch the UI. On web this
/// is not used — the service worker (`web/firebase-messaging-sw.js`)
/// handles background messages instead — so it is only registered
/// off-web. The project is web-only by design (no native Firebase
/// app is registered), so on mobile this initialises with no platform
/// config and returns quietly; the handler exists so the Dart side is
/// already wired when a native app is registered.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // No native Firebase configuration: nothing to deliver to.
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
  }
  runApp(const CampReadyStartup());
}

class CampReadyStartup extends StatefulWidget {
  const CampReadyStartup({super.key});

  @override
  State<CampReadyStartup> createState() => _CampReadyStartupState();
}

class _CampReadyStartupState extends State<CampReadyStartup> {
  late Future<CampReadyServices> services = initialize();

  Future<CampReadyServices> initialize() async {
    const demo = bool.fromEnvironment('LOCAL_DEMO');
    return demo ? CampReadyServices.local() : CampReadyServices.initialize();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CampReadyServices>(
    future: services,
    builder: (context, snapshot) {
      if (snapshot.hasData) return CampReady(services: snapshot.data!);
      return MaterialApp(
        initialRoute: '/',
        theme: campTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'CampReady could not connect to Firebase. Check your connection and platform configuration.',
                        ),
                        FilledButton(
                          onPressed: () =>
                              setState(() => services = initialize()),
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
