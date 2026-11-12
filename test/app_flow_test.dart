import 'package:campready/models/stay.dart';
import 'package:campready/repositories/location_repository.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/material.dart';
import 'package:campready/app.dart';
import 'package:campready/screens/splash_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/app_harness.dart';

void main() {
  setUpAll(loadFonts);

  group('Start and auth', () {
    testWidgets('cold start plays the splash, then welcome', (tester) async {
      await pumpApp(tester, CampReadyServices.local(), route: '/splash');
      expect(screenOf(tester), 'welcome');
      expect(find.text('Your next weekend,\nwell prepared.'), findsOneWidget);
    });

    testWidgets('splash animates in before leaving', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CampReady(services: CampReadyServices.local(), clock: () => today),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SplashView), findsOneWidget);
      double titleOpacity() => tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('CampReady'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      expect(titleOpacity(), lessThan(0.05));
      await tester.pump(const Duration(milliseconds: 1900));
      expect(titleOpacity(), greaterThan(0.9));
      await tester.pumpAndSettle();
      expect(find.byType(SplashView), findsNothing);
      expect(screenOf(tester), 'welcome');
    });

    testWidgets('restored session skips welcome', (tester) async {
      final (services, _) = await signedIn();
      await pumpApp(tester, services, route: '/splash');
      expect(screenOf(tester), 'explore');
    });

    testWidgets('guest can explore but saving asks to sign in', (tester) async {
      await pumpApp(tester, CampReadyServices.local(), route: '/welcome');
      await tap(tester, 'Explore as a guest');
      expect(screenOf(tester), 'guest');
      await tap(tester, 'Redwood Grove');
      expect(screenOf(tester), 'detail');
      expect(find.text('Your dates · Sunny'), findsNothing);
      expect(find.text('Next 3 days · Sunny'), findsOneWidget);
      await tap(tester, 'Save campsite');
      expect(screenOf(tester), 'authgate');
    });

    testWidgets('sign-up validates every field', (tester) async {
      final services = CampReadyServices.local();
      await pumpApp(tester, services, route: '/signup');
      await tap(tester, 'Create account');
      expect(find.text('Enter Email'), findsOneWidget);
      expect(find.text('Enter Password'), findsOneWidget);
      await enter(tester, 'Email', 'not-an-email');
      await enter(tester, 'Password', 'short');
      await tap(tester, 'Create account');
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      await enter(tester, 'Your name', 'Alex');
      await enter(tester, 'Email', 'alex@example.com');
      await enter(tester, 'Password', 'campready123');
      await tap(tester, 'Create account');
      expect(screenOf(tester), 'location');
      expect(services.auth.currentUser?.displayName, 'Alex');
      expect(services.store.profile(services.auth.currentUser!.uid), isNotNull);
    });

    testWidgets('wrong password shows a clear error', (tester) async {
      final (services, _) = await signedIn();
      await services.auth.signOut();
      await pumpApp(tester, services, route: '/signin');
      await enter(tester, 'Email', 'owner@example.com');
      await enter(tester, 'Password', 'wrongpass1');
      await tap(tester, 'Sign in');
      expect(find.text('Check your email and password'), findsOneWidget);
      expect(screenOf(tester), 'signin');
      await enter(tester, 'Password', 'campready123');
      await tap(tester, 'Sign in');
      expect(screenOf(tester), 'explore');
    });

    testWidgets('forgot password sends the reset email', (tester) async {
      final services = CampReadyServices.local();
      await pumpApp(tester, services, route: '/forgot');
      await enter(tester, 'Email', 'Owner@Example.com');
      await tap(tester, 'Send reset link');
      expect(screenOf(tester), 'resetsent');
      expect(find.textContaining('Owner@Example.com'), findsOneWidget);
      expect(
        services.store.passwordResetRequested('owner@example.com'),
        isTrue,
      );
    });

    testWidgets('sign out clears the account and returns to welcome', (
      tester,
    ) async {
      final (services, user) = await signedIn();
      await services.firestore.saveCampsite(
        user.uid,
        const SavedCampsite(siteId: 'redwood-grove', name: 'Redwood Grove'),
      );
      await pumpApp(tester, services, route: '/profile');
      expect(find.text('Owner'), findsOneWidget);
      await tap(tester, 'Sign out');
      await tap(tester, 'Sign out');
      expect(screenOf(tester), 'welcome');
      expect(services.auth.currentUser, isNull);
      await services.auth.signUp(
        email: 'other@example.com',
        password: 'campready123',
      );
      await pumpApp(tester, services, route: '/saved');
      expect(find.text('Save a little inspiration'), findsOneWidget);
      expect(find.text('Redwood Grove'), findsNothing);
    });
  });

  group('Location', () {
    testWidgets('allowed location sorts campsites nearest first', (
      tester,
    ) async {
      final (services, _) = await signedIn();
      await pumpApp(
        tester,
        services,
        route: '/location',
        location: fakeLocation(LocationStatus.granted, 37.126, -122.122),
      );
      await tap(tester, 'Allow location');
      expect(screenOf(tester), 'explore');
      expect(find.text('Closest to you'), findsOneWidget);
      final sunset = tester.getTopLeft(find.text('Sunset Ridge').first);
      final redwood = tester.getTopLeft(find.text('Redwood Grove').first);
      expect(sunset.dy, lessThan(redwood.dy));
      expect(find.textContaining('MI AWAY'), findsWidgets);
    });

    for (final (status, message) in [
      (LocationStatus.denied, 'Location access is off.'),
      (LocationStatus.deniedForever, 'Location is blocked'),
      (LocationStatus.serviceDisabled, 'Location services are off'),
    ]) {
      testWidgets('${status.name} falls back to a destination search', (
        tester,
      ) async {
        final location = fakeLocation(status);
        await pumpApp(
          tester,
          CampReadyServices.local(),
          route: '/location',
          location: location,
        );
        await tap(tester, 'Allow location');
        expect(screenOf(tester), 'denied');
        expect(find.textContaining(message), findsOneWidget);
        await tap(tester, 'Try location again');
        if (status == LocationStatus.deniedForever) {
          verify(() => location.openAppSettings()).called(1);
        } else if (status == LocationStatus.serviceDisabled) {
          verify(() => location.openLocationSettings()).called(1);
        }
        verify(() => location.currentPosition()).called(2);
        await enter(tester, 'Destination', 'Boulder');
        await tap(tester, 'Search campsites');
        expect(screenOf(tester), 'guest');
        expect(find.text('Sunset Ridge'), findsOneWidget);
        expect(find.text('Redwood Grove'), findsNothing);
      });
    }
  });

  group('Saved campsites', () {
    testWidgets('save and unsave are stored in Firestore', (tester) async {
      final (services, user) = await signedIn();
      await pumpApp(tester, services, route: '/campsite/redwood-grove');
      await tap(tester, 'Save campsite');
      expect(screenOf(tester), 'detailsaved');
      expect(
        (await services.firestore.savedCampsites(user.uid))
            .map((s) => s.siteId),
        ['redwood-grove'],
      );
      await tap(tester, 'Remove from saved');
      expect(await services.firestore.savedCampsites(user.uid), isEmpty);
    });

    testWidgets('removing one saved campsite keeps the other', (tester) async {
      final (services, user) = await signedIn();
      await services.firestore.saveCampsite(
        user.uid,
        const SavedCampsite(siteId: 'Redwood Grove', name: 'Redwood Grove'),
      );
      await services.firestore.saveCampsite(
        user.uid,
        const SavedCampsite(siteId: 'sunset-ridge', name: 'Sunset Ridge'),
      );
      await pumpApp(tester, services, route: '/saved');
      expect(find.text('2 saved campsites'), findsOneWidget);
      await tap(tester, 'Remove Redwood Grove');
      expect(find.text('1 saved campsite'), findsOneWidget);
      expect(
        (await services.firestore.savedCampsites(user.uid))
            .map((s) => s.siteId),
        ['sunset-ridge'],
      );
      await tap(tester, 'Sunset Ridge');
      expect(screenOf(tester), 'detail');
      expect(siteOf(tester), 'sunset-ridge');
    });
  });

  group('Sync', () {
    testWidgets('a trip shared from another device shows on the Trips tab', (
      tester,
    ) async {
      final (services, _) = await signedIn();
      await pumpApp(tester, services, route: '/explore');
      expect(find.text('Sunset Ridge  ›'), findsNothing);
      // Written by the friend's device; this app has not reloaded yet.
      services.store.putTrip(
        TripRecord(
          id: TripRecord.idFor('friend-uid', 'Sunset Ridge'),
          ownerUid: 'friend-uid',
          ownerEmail: 'friend@example.com',
          site: 'Sunset Ridge',
          siteId: 'sunset-ridge',
          dates: 'Dec 4–6, 2026',
          sharedWithEmails: const ['owner@example.com'],
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Trips'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sunset Ridge  ›'), findsOneWidget);
      expect(find.text('Shared by friend@example.com'), findsOneWidget);
    });
  });

  group('Camera', () {
    // 1x1 transparent PNG.
    const pixel =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

    testWidgets('taking a photo saves it to the profile', (tester) async {
      final (services, user) = await signedIn();
      final photo = FakePhoto();
      when(() => photo.pick(camera: true)).thenAnswer((_) async => pixel);
      await pumpApp(tester, services, route: '/profile', photo: photo);
      expect(find.text('O'), findsOneWidget);
      await tap(tester, 'Take photo');
      expect(find.text('Profile photo saved.'), findsOneWidget);
      expect(find.text('O'), findsNothing);
      expect((await services.firestore.userSettings(user.uid))['photo'], pixel);
    });

    testWidgets('a denied camera shows why and saves nothing', (tester) async {
      final (services, user) = await signedIn();
      final photo = FakePhoto();
      when(() => photo.pick(camera: true)).thenThrow(
        StateError(
          'Camera access is off. Allow it in Settings to take a photo.',
        ),
      );
      await pumpApp(tester, services, route: '/profile', photo: photo);
      await tap(tester, 'Take photo');
      expect(find.textContaining('Camera access is off'), findsOneWidget);
      expect(
        (await services.firestore.userSettings(user.uid))['photo'],
        isNull,
      );
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      final (services, _) = await signedIn();
      final photo = FakePhoto();
      when(() => photo.pick(camera: false)).thenAnswer((_) async => null);
      await pumpApp(tester, services, route: '/profile', photo: photo);
      await tap(tester, 'Choose photo');
      expect(find.text('Profile photo saved.'), findsNothing);
      expect(find.text('O'), findsOneWidget);
    });
  });

  group('Booking', () {
    testWidgets('dates come from the date picker and create a trip', (
      tester,
    ) async {
      final (services, user) = await signedIn();
      await pumpApp(tester, services, route: '/campsite/redwood-grove');
      await tap(tester, 'Check availability');
      expect(screenOf(tester), 'dates');
      await tap(tester, 'Use selected dates');
      expect(
        find.text('Choose your arrival and checkout dates.'),
        findsOneWidget,
      );
      await pickRange(tester, 12, 14);
      expect(find.text('Nov 12–14, 2026'), findsOneWidget);
      await tap(tester, 'Use selected dates');
      expect(screenOf(tester), 'review');
      expect(
        find.text(r'2 nights × $65 = $130 · Simulated, no charge'),
        findsOneWidget,
      );
      await tap(tester, 'Request to book');
      expect(screenOf(tester), 'confirmed');
      final trips = await services.firestore.tripsForUser(user.uid, user.email);
      expect(
        trips.single.stay,
        Stay(DateTime(2026, 11, 12), DateTime(2026, 11, 14)),
      );
      expect(trips.single.siteId, 'redwood-grove');
      await tap(tester, 'View trip');
      expect(screenOf(tester), 'trip');
      expect(tripOf(tester), trips.single.id);
      expect(find.text('Nov 12–14, 2026'), findsOneWidget);
    });

    testWidgets('the free plan allows one trip, then shows Plus', (
      tester,
    ) async {
      final (services, user) = await signedIn();
      await services.firestore.createTrip(
        TripRecord(
          id: TripRecord.idFor(user.uid, 'Redwood Grove'),
          ownerUid: user.uid,
          ownerEmail: user.email,
          site: 'Redwood Grove',
          siteId: 'redwood-grove',
          dates: 'Nov 12–14, 2026',
          stay: Stay(DateTime(2026, 11, 12), DateTime(2026, 11, 14)),
        ),
      );
      await pumpApp(tester, services, route: '/campsite/sunset-ridge');
      await tap(tester, 'Check availability');
      await pickRange(tester, 20, 22);
      await tap(tester, 'Use selected dates');
      await tap(tester, 'Request to book');
      expect(screenOf(tester), 'premium');
      expect(
        (await services.firestore.tripsForUser(user.uid, user.email)).length,
        1,
      );
    });

    testWidgets('editing dates on a removed trip keeps the old plan', (
      tester,
    ) async {
      final (services, user) = await signedIn();
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: TripRecord.idFor(user.uid, 'Redwood Grove'),
          ownerUid: user.uid,
          ownerEmail: user.email,
          site: 'Redwood Grove',
          siteId: 'redwood-grove',
          dates: 'Nov 12–14, 2026',
          stay: Stay(DateTime(2026, 11, 12), DateTime(2026, 11, 14)),
        ),
      );
      await pumpApp(tester, services, route: '/trips/${trip.id}');
      await tap(tester, 'Edit dates');
      expect(screenOf(tester), 'dates');
      await services.firestore.deleteTrip(trip.id);
      await pickRange(tester, 20, 22);
      await tap(tester, 'Use selected dates');
      expect(find.text('This trip was removed.'), findsOneWidget);
      expect(screenOf(tester), 'dates');
    });
  });
}

Future<void> pickRange(WidgetTester tester, int start, int end) async {
  await tap(tester, 'Choose dates');
  await tester.tap(find.text('$start').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('$end').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
}
