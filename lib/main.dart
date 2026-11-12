import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/services.dart';
import 'theme.dart';

/// Runs when a push arrives while the app is in the background or
/// closed (Android and iOS). The system shows the notification itself.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  runApp(CampReadyStartup(initialRoute: _startRoute()));
}

/// The address the app was opened at, so web deep links survive the
/// Firebase start-up screen.
String _startRoute() {
  if (!kIsWeb) return '/splash';
  final start = Uri.base;
  if (start.path.isEmpty || start.path == '/') return '/splash';
  return start.hasQuery ? '${start.path}?${start.query}' : start.path;
}

class CampReadyStartup extends StatefulWidget {
  const CampReadyStartup({super.key, required this.initialRoute});

  final String initialRoute;

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
      if (snapshot.hasData) {
        return CampReady(
          services: snapshot.data!,
          initialRoute: widget.initialRoute,
        );
      }
      return MaterialApp(
        theme: campTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'CampReady could not connect. Check your connection and try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
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
