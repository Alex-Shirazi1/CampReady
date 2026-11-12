// Regenerates docs/screenshots/<route>.png for every named route.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//   flutter test tool/screenshots_test.dart --update-goldens \
//     --dart-define=SHOW_DEMO=true      # the demo-only screens
import 'package:campready/app.dart';
import 'package:campready/router.dart';
import 'package:campready/screens.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test/support/app_harness.dart';

const _signedOut = {
  'splash',
  'splash-ready',
  'welcome',
  'signin',
  'signinfilled',
  'signinerror',
  'signup',
  'signupfilled',
  'signuperror',
  'forgot',
  'resetsent',
  'authgate',
  'guest',
  'searchguest',
  'location-permission',
};

Future<void> _precacheImages(WidgetTester tester) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final images = manifest.listAssets().where((a) => a.endsWith('.png'));
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final asset in images) {
      await precacheImage(AssetImage(asset), context);
    }
  });
}

void main() {
  setUpAll(loadFonts);

  for (final page in campPages) {
    if (showDemoBuild != demoRoutes.contains(page.route)) continue;
    testWidgets(page.route, (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      GoRouter.optionURLReflectsImperativeAPIs = true;
      final services = _signedOut.contains(page.route)
          ? CampReadyServices.local()
          : await seeded();
      await tester.pumpWidget(
        CampReady(
          services: services,
          initialRoute: '/${page.route}',
          locationRepository: fakeLocation(),
          weatherRepository: fakeWeather(),
          photoRepository: FakePhoto(),
          clock: () => today,
        ),
      );
      if (page.route.startsWith('splash')) {
        await tester.pump(const Duration(milliseconds: 2100));
      } else {
        await tester.pumpAndSettle();
        await _precacheImages(tester);
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../docs/screenshots/${page.route}.png'),
      );
      if (page.route.startsWith('splash')) {
        await tester.pumpAndSettle();
      }
    });
  }
}
