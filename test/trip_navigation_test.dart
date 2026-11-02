import 'package:campready/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Future<void> open(WidgetTester tester, String route, DemoState state) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      CampReady(key: UniqueKey(), initialRoute: '/$route', initialState: state),
    );
    await tester.pumpAndSettle();
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

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  String currentRoute(WidgetTester tester) =>
      tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route;

  List<String> tripValues(TripDetails trip) => [
    trip.dates,
    trip.status,
    trip.downloadedDates,
    trip.invitation,
  ];

  DemoState twoTrips() {
    final state = DemoState()
      ..signedIn = true
      ..plus = true;
    state.trips.addAll(['Redwood Grove', 'Sunset Ridge']);
    state.details['Redwood Grove'] = TripDetails()
      ..dates = 'Oct 23–25, 2026'
      ..status = 'Accepted'
      ..downloadedDates = 'Oct 23–25, 2026'
      ..invitation = 'Invitation pending · redwood@example.com';
    state.details['Sunset Ridge'] = TripDetails()
      ..dates = 'Oct 30–Nov 1, 2026'
      ..status = 'Declined'
      ..downloadedDates = 'Oct 30–Nov 1, 2026'
      ..invitation = 'Invitation pending · sunset@example.com';
    return state;
  }

  Future<void> bookTrip(
    WidgetTester tester,
    DemoState state,
    String site,
  ) async {
    final redwood = site == 'Redwood Grove';
    await open(tester, 'explore', state);
    await tap(tester, redwood ? 'Redwood Grove' : 'Sunset Ridge  ›');
    await tap(tester, redwood ? 'Check availability' : 'Plan a trip here');
    await tap(tester, redwood ? 'October 23–25' : 'October 30–November 1');
    await tap(tester, 'Use selected dates');
    await tap(tester, 'Request to book · Demo');
    await tap(tester, 'View trip');
    await tap(tester, 'Booking response');
    await tap(tester, redwood ? 'Host accepts' : 'Host declines');
    await tap(tester, 'Return to trip');
    await tap(tester, 'Share & group');
    await tester.enterText(
      find.byType(TextFormField),
      redwood ? 'redwood@example.com' : 'sunset@example.com',
    );
    await tap(tester, 'Send invitation');
    await tap(tester, 'Return to trip');
    await tap(tester, 'Download summary');
    await tap(tester, 'Complete download');
  }

  for (final removed in ['Redwood Grove', 'Sunset Ridge']) {
    final kept = removed == 'Redwood Grove' ? 'Sunset Ridge' : 'Redwood Grove';

    testWidgets(
      'Removing booked $removed preserves $kept and clears deleted history',
      (tester) async {
        final state = DemoState()
          ..signedIn = true
          ..plus = true;
        await bookTrip(tester, state, 'Redwood Grove');
        await bookTrip(tester, state, 'Sunset Ridge');
        expect(tripValues(state.details['Redwood Grove']!), [
          'Oct 23–25, 2026',
          'Accepted',
          'Oct 23–25, 2026',
          'Invitation pending · redwood@example.com',
        ]);
        expect(tripValues(state.details['Sunset Ridge']!), [
          'Oct 30–Nov 1, 2026',
          'Declined',
          'Oct 30–Nov 1, 2026',
          'Invitation pending · sunset@example.com',
        ]);
        final keptValues = tripValues(state.details[kept]!);

        await open(tester, 'trips', state);
        await tap(tester, removed);
        await tap(tester, 'Remove trip');
        await tap(tester, 'Remove trip');
        expect(currentRoute(tester), 'trips');
        expect(state.trips, {kept});
        expect(state.details.keys, unorderedEquals([kept]));
        expect(tripValues(state.details[kept]!), keptValues);
        expect(state.alerts, isTrue);
        expect(
          GoRouter.of(tester.element(find.byType(DesignScreen).last)).canPop(),
          isFalse,
        );

        await systemBack(tester);
        expect(currentRoute(tester), 'trips');
        expect(find.text('Keep trip'), findsNothing);
        await tap(tester, kept);
        expect(find.text(keptValues[0]), findsOneWidget);
        expect(find.text('${keptValues[1]} · Demo'), findsOneWidget);
        await tap(tester, 'All trips');
        await tester.pump();
        expect(state.details.keys, unorderedEquals([kept]));
        expect(tripValues(state.details[kept]!), keptValues);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Back restores $removed data and removes that trip only', (
      tester,
    ) async {
      final state = twoTrips();
      final restoredValues = tripValues(state.details[removed]!);
      final keptValues = tripValues(state.details[kept]!);
      await open(tester, 'trips', state);
      await tap(tester, removed);
      await tap(tester, 'All trips');
      await tap(tester, kept);
      await tap(tester, '‹ Back');
      await systemBack(tester);
      expect(
        currentRoute(tester),
        removed == 'Redwood Grove' ? 'trip' : 'ridgetrip',
      );
      expect(find.text(removed), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Trip dates'),
        -220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text(restoredValues[0]), findsOneWidget);
      expect(find.text('${restoredValues[1]} · Demo'), findsOneWidget);
      await tap(tester, 'Remove trip');
      await tap(tester, 'Remove trip');
      expect(state.trips, {kept});
      expect(state.details.keys, unorderedEquals([kept]));
      expect(tripValues(state.details[kept]!), keptValues);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Back restores the original $removed share page actions', (
      tester,
    ) async {
      final state = twoTrips();
      final keptValues = tripValues(state.details[kept]!);
      await open(tester, 'trips', state);
      await tap(tester, removed);
      await tap(tester, 'Share & group');
      await tap(tester, 'Return to trip');
      await tap(tester, 'All trips');
      await tap(tester, kept);
      await tap(tester, '‹ Back');
      await systemBack(tester);
      await systemBack(tester);
      expect(currentRoute(tester), 'share');
      expect(find.text(removed), findsOneWidget);
      expect(find.text(state.details[removed]!.dates), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'new@example.com');
      await tap(tester, 'Send invitation');
      expect(
        state.details[removed]!.invitation,
        'Invitation pending · new@example.com',
      );
      expect(tripValues(state.details[kept]!), keptValues);
      expect(tester.takeException(), isNull);
    });
  }

  for (final route in [
    'dates',
    'review',
    'trip',
    'ridgetrip',
    'share',
    'booking-response',
    'downloaded',
    'your-camping-group',
  ]) {
    testWidgets('Viewing $route does not create a saved trip record', (
      tester,
    ) async {
      final state = DemoState()..signedIn = true;
      await open(tester, route, state);
      await tester.pump();
      expect(state.trips, isEmpty);
      expect(state.details, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final preview in {
    'booking-response': 'Host accepts',
    'save-for-offline-use': 'Complete download',
  }.entries) {
    testWidgets('${preview.value} requires an existing saved trip', (
      tester,
    ) async {
      final state = DemoState()
        ..signedIn = true
        ..plus = true;
      await open(tester, preview.key, state);
      await tap(tester, preview.value);
      expect(currentRoute(tester), 'this-trip-is-no-longer-available');
      expect(find.text('This trip is no longer available'), findsOneWidget);
      expect(state.trips, isEmpty);
      expect(state.details, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final restored in {
    'trip': 'Redwood Grove',
    'ridgetrip': 'Sunset Ridge',
    'share': 'Redwood Grove',
  }.entries) {
    testWidgets('Restored ${restored.key} cannot reopen a deleted trip', (
      tester,
    ) async {
      final state = twoTrips();
      final removed = restored.value;
      final kept = removed == 'Redwood Grove'
          ? 'Sunset Ridge'
          : 'Redwood Grove';
      final keptValues = tripValues(state.details[kept]!);
      await open(tester, 'trips', state);
      await tap(tester, removed);
      await tap(tester, 'Remove trip');
      await tap(tester, 'Remove trip');
      GoRouter.of(tester.element(find.byType(DesignScreen).last))
          .goNamed(restored.key, extra: removed);
      await tester.pumpAndSettle();
      expect(currentRoute(tester), 'this-trip-is-no-longer-available');
      expect(find.text('This trip is no longer available'), findsOneWidget);
      expect(state.trips, {kept});
      expect(state.details.keys, unorderedEquals([kept]));
      expect(tripValues(state.details[kept]!), keptValues);
      expect(tester.takeException(), isNull);
    });
  }
}
