import 'package:flutter/material.dart';

import 'app.dart';
import 'services/services.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
