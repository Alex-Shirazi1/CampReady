import 'dart:convert';
import 'dart:io';

import 'package:campready/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final screens = (jsonDecode(
    File('assets/screens.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    loader.addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    loader.addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
    loader.addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();
  });
  Future<void> open(
    WidgetTester tester,
    String route, [
    DemoState? state,
  ]) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      CampReady(
        key: UniqueKey(),
        screens: screens,
        initialRoute: '/$route',
        initialState: state,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        220,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  testWidgets('Guest entry, conditions, auth gate and real signup inputs', (
    tester,
  ) async {
    await open(tester, 'welcome');
    await tap(tester, 'Get started');
    expect(find.text('Find your outside.'), findsOneWidget);
    await tap(tester, 'Redwood Grove');
    await tap(tester, 'Check availability');
    await tap(tester, 'Create an account');
    await tap(tester, 'Create account');
    expect(find.text('Enter Your name'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Alex');
    await tester.enterText(fields.at(1), 'alex@example.com');
    await tester.enterText(fields.at(2), 'campready123');
    await tap(tester, 'Create account');
    expect(find.text('Find your nearby outside'), findsOneWidget);
    await tap(tester, 'Allow location');
    await tap(tester, 'Allow location');
    expect(find.text('Find your outside.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Booking, sharing and consistent five-tab navigation', (
    tester,
  ) async {
    await open(tester, 'guide');
    await tap(tester, 'Explore and plan');
    await tap(tester, 'Redwood Grove');
    await tap(tester, 'Check availability');
    await tap(tester, 'Use selected dates');
    await tap(tester, 'Request to book · Demo');
    await tap(tester, 'View trip');
    await tap(tester, 'Share & group');
    final email = find.byType(TextFormField);
    await tester.enterText(email, 'friend@example.com');
    await tap(tester, 'Send invitation');
    await tap(tester, 'Open recipient view');
    await tap(tester, 'Accept invitation');
    expect(find.text('You joined the trip'), findsOneWidget);
    await tap(tester, 'Return to owner');
    await tap(tester, 'All trips');
    for (final label in [
      'Saved',
      'Alerts',
      'Profile',
      'Explore',
      'Trips',
      'Alerts',
      'Saved',
      'Profile',
      'Trips',
    ]) {
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Filters, profile validation, Plus and offline download flows', (
    tester,
  ) async {
    await open(tester, 'guide');
    await tap(tester, 'Account and Plus');
    await tap(tester, 'Edit profile');
    await tester.enterText(find.byType(TextFormField), '');
    await tap(tester, 'Save profile');
    expect(find.text('Enter Display name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tap(tester, 'Save profile');
    expect(find.text('Alex'), findsOneWidget);
    await tap(tester, 'Done');
    await tap(tester, 'Explore Plus');
    await tap(tester, 'Try Plus · Demo upgrade');
    await tap(tester, 'Confirm demo upgrade');
    await tap(tester, 'Upgrade succeeds');
    expect(find.text('Welcome to Plus'), findsOneWidget);
    await tap(tester, 'Continue planning');
    await tap(tester, 'Filters');
    await tap(tester, 'Show matching campsites');
    expect(find.text('Matching campsites'), findsOneWidget);
    await tap(tester, 'Redwood Grove');
    await tap(tester, 'Check availability');
    await tap(tester, 'Use selected dates');
    await tap(tester, 'Request to book · Demo');
    await tap(tester, 'View trip');
    await tap(tester, 'Download summary');
    await tap(tester, 'Complete download');
    await tap(tester, 'Open downloaded summary');
    expect(find.text('Offline trip summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Cancel discards notification changes and Save keeps them', (
    tester,
  ) async {
    final state = DemoState();
    await open(tester, 'preferences', state);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tap(tester, 'Cancel');
    expect(state.alerts, isTrue);
    await open(tester, 'preferences', state);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tap(tester, 'Save preferences');
    expect(state.alerts, isFalse);
  });
  testWidgets('Each booking keeps its dates, response and offline copy', (
    tester,
  ) async {
    final state = DemoState()
      ..signedIn = true
      ..plus = true;
    await open(tester, 'dates', state);
    await tap(tester, 'October 23–25');
    await tap(tester, 'Use selected dates');
    await tap(tester, 'Request to book · Demo');
    await tap(tester, 'View trip');
    await tap(tester, 'Booking response');
    await tap(tester, 'Host accepts');
    await tap(tester, 'Return to trip');
    await tap(tester, 'Download summary');
    await tap(tester, 'Complete download');
    await open(tester, 'explore', state);
    await tap(tester, 'Sunset Ridge  ›');
    await tap(tester, 'Plan a trip here');
    expect(find.text('Sunset Ridge · October 2026'), findsOneWidget);
    await tap(tester, 'Use selected dates');
    await tap(tester, 'Request to book · Demo');
    await tap(tester, 'View trip');
    await tap(tester, 'Share & group');
    expect(find.text('Sunset Ridge'), findsWidgets);
    expect(state.trip.status, 'Request pending');
    await open(tester, 'alerts', state);
    await tap(tester, 'Redwood: fire restriction');
    await tap(tester, 'View affected trip');
    expect(state.site, 'Redwood Grove');
    expect(state.trip.dates, 'Oct 23–25, 2026');
    expect(state.trip.status, 'Accepted');
    expect(state.trip.downloadedDates, state.trip.dates);
    state.trip.dates = 'Oct 30–Nov 1, 2026';
    await open(tester, 'downloaded-summaries', state);
    await tap(tester, 'Redwood Grove · Oct 23–25, 2026');
    expect(find.text('Your offline copy is older'), findsOneWidget);
    expect(find.text('Oct 23–25, 2026'), findsOneWidget);
  });
  testWidgets('Incompatible filters reset and Plus profile keeps membership', (
    tester,
  ) async {
    final state = DemoState()
      ..travelers = '4 travelers'
      ..plus = true
      ..signedIn = true;
    await open(tester, 'filters', state);
    await tap(tester, 'Show matching campsites');
    await tap(tester, 'Reset filters');
    await tap(tester, 'Show matching campsites');
    expect(find.text('Matching campsites'), findsOneWidget);
    await open(tester, 'profileplus', state);
    await tap(tester, 'Edit profile');
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tap(tester, 'Save profile');
    await tap(tester, 'Done');
    expect(find.text('Manage membership'), findsWidgets);
  });
  for (final screen in screens) {
    final route = screen['route'] as String;
    testWidgets('Render $route', (tester) async {
      final state = DemoState();
      if (route.startsWith('ridge')) state.site = 'Sunset Ridge';
      if ([
        'trips',
        'alerts',
        'downloaded',
        'downloaded-summaries',
        'ready-for-offline-use',
        'your-offline-copy-is-older',
      ].contains(route)) {
        state.trips.add(state.site);
        state.trip.downloadedDates = route == 'your-offline-copy-is-older'
            ? 'Oct 23–25, 2026'
            : state.trip.dates;
      }
      if (route == 'your-camping-group') {
        state.trip.invitation = 'Invitation pending · friend@example.com';
      }
      await open(tester, route, state);
      expect(tester.takeException(), isNull, reason: route);
      if (const bool.fromEnvironment('SCREENSHOTS')) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        });
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../docs/screenshots/$route.png'),
        );
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
