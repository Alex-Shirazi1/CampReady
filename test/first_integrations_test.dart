import 'package:campready/models/stay.dart';
// First Integrations service tests (local mode only — no Firebase
// project, no network). The same API is used in configured mode;
// these tests pin the local fallback behaviour the UI relies on.
import 'package:campready/app.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService (local mode)', () {
    test('sign up, sign in, sign out, and auth state stream', () async {
      final services = CampReadyServices.local();
      final auth = services.auth;
      expect(auth.currentUser, isNull);
      expect(services.mode, 'local');

      final seen = <AppUser?>[];
      final sub = auth.authStateChanges.listen(seen.add);
      final user = await auth.signUp(
        email: 'alex@example.com',
        password: 'campready123',
        displayName: 'Alex',
      );
      expect(user.email, 'alex@example.com');
      expect(user.displayName, 'Alex');
      expect(auth.currentUser?.uid, user.uid);
      expect(auth.isSignedIn, isTrue);

      await auth.signOut();
      expect(auth.currentUser, isNull);
      await auth.signIn(email: 'alex@example.com', password: 'campready123');
      expect(auth.currentUser?.email, 'alex@example.com');
      await sub.cancel();
      expect(seen, contains(user));
      expect(seen.last, isNotNull);
    });

    test('duplicate email, wrong password, short password rejected', () async {
      final auth = CampReadyServices.local().auth;
      await auth.signUp(email: 'dup@example.com', password: 'campready123');
      await expectLater(
        () => auth.signUp(email: 'dup@example.com', password: 'campready123'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        () => auth.signIn(email: 'dup@example.com', password: 'wrongpass'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        () => auth.signUp(email: 'new@example.com', password: 'short'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        () => auth.signUp(email: 'not-an-email', password: 'campready123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('sample account from the Figma design signs in locally', () async {
      final auth = CampReadyServices.local().auth;
      final user = await auth.signIn(
        email: 'john.doe@example.com',
        password: 'campready123',
      );
      expect(user.displayName, 'John Doe');
    });

    test('password reset is recorded locally, display name updates', () async {
      final services = CampReadyServices.local();
      final user = await services.auth.signUp(
        email: 'reset@example.com',
        password: 'campready123',
        displayName: 'Reset',
      );
      await services.auth.sendPasswordReset('reset@example.com');
      expect(
        services.store.passwordResetRequested('reset@example.com'),
        isTrue,
      );
      final updated = await services.auth.updateDisplayName('Reset Renamed');
      expect(updated?.displayName, 'Reset Renamed');
      // The local store keeps the profile in step with the auth record.
      expect(
        (await services.firestore.getUserProfile(user.uid))?.displayName,
        'Reset Renamed',
      );
      await services.firestore.saveUserProfile(updated!);
      expect(
        (await services.firestore.getUserProfile(user.uid))?.displayName,
        'Reset Renamed',
      );
    });
  });

  group('FirestoreService (local mode)', () {
    test('saved campsite CRUD', () async {
      final services = CampReadyServices.local();
      const site = SavedCampsite(
        siteId: 'Redwood Grove',
        name: 'Redwood Grove',
        pricePerNight: r'$65 / night',
      );
      await services.firestore.saveCampsite('uid-1', site);
      expect(
        await services.firestore.isCampsiteSaved('uid-1', 'Redwood Grove'),
        isTrue,
      );
      expect((await services.firestore.savedCampsites('uid-1')).length, 1);
      await services.firestore.removeCampsite('uid-1', 'Redwood Grove');
      expect(
        await services.firestore.isCampsiteSaved('uid-1', 'Redwood Grove'),
        isFalse,
      );
    });

    test('trip CRUD, sharing, and visibility for the invitee', () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
        displayName: 'Owner',
      );
      final invitee = await services.auth.signUp(
        email: 'friend@example.com',
        password: 'campready123',
        displayName: 'Friend',
      );
      final trip = TripRecord(
        id: 'trip_1',
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
      );
      await services.firestore.createTrip(trip);
      expect(
        (await services.firestore.tripsForUser(owner.uid, owner.email)).length,
        1,
      );
      expect(
        await services.firestore.tripsForUser(invitee.uid, invitee.email),
        isEmpty,
      );
      final shared = await services.firestore.shareTrip(
        tripId: 'trip_1',
        email: 'friend@example.com',
      );
      expect(shared.sharedWithEmails, contains('friend@example.com'));
      expect(shared.invitation, contains('friend@example.com'));
      expect(
        (await services.firestore.tripsForUser(
          invitee.uid,
          invitee.email,
        )).length,
        1,
      );
      final updated = shared.copyWith(
        stay: Stay(DateTime(2026, 10, 30), DateTime(2026, 11, 1)),
      );
      await services.firestore.updateTrip(updated);
      expect(
        (await services.firestore.getTrip('trip_1'))?.dates,
        'Oct 30–Nov 1, 2026',
      );
      await services.firestore.deleteTrip('trip_1');
      expect(await services.firestore.getTrip('trip_1'), isNull);
    });

    test('notification records round-trip and mark read', () async {
      final services = CampReadyServices.local();
      const notification = AppNotification(
        id: 'n1',
        title: 'Redwood Grove: dates changed',
        body: 'Your trip dates are now Oct 30–Nov 1, 2026.',
        site: 'Redwood Grove',
      );
      await services.firestore.addNotification('uid-1', notification);
      expect((await services.firestore.notifications('uid-1')).length, 1);
      await services.firestore.markNotificationRead('uid-1', 'n1');
      expect(
        (await services.firestore.notifications('uid-1')).first.read,
        isTrue,
      );
    });
  });

  group('MessagingService (local mode)', () {
    test('token save and condition-change notification delivery', () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner2@example.com',
        password: 'campready123',
        displayName: 'Owner',
      );
      await services.auth.signUp(
        email: 'friend2@example.com',
        password: 'campready123',
        displayName: 'Friend',
      );
      expect(await services.messaging.requestPermission(), isTrue);
      final token = await services.messaging.getToken(owner.uid);
      expect(token, startsWith('local-token-'));
      expect(services.store.tokens(owner.uid), contains(token));

      // The notification is about a real shared trip: invitee delivery
      // is trip-scoped, so the trip must exist and be shared first.
      await services.firestore.createTrip(
        TripRecord(
          id: 'trip_2',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Sunset Ridge',
          dates: 'Oct 23–25, 2026',
        ),
      );
      await services.firestore.shareTrip(
        tripId: 'trip_2',
        email: 'friend2@example.com',
      );

      final notification = await services.messaging.notifyConditionChange(
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        tripId: 'trip_2',
        site: 'Sunset Ridge',
        title: 'Sunset Ridge: dates changed',
        body: 'Your trip dates are now Oct 30–Nov 1, 2026.',
        sharedWithEmails: ['friend2@example.com'],
      );
      expect(notification.title, contains('dates changed'));
      expect((await services.firestore.notifications(owner.uid)).length, 1);
      // The invitee's account also gets the record.
      final invitee = services.store.findUser('friend2@example.com')!;
      expect((await services.firestore.notifications(invitee.uid)).length, 1);
    });
  });

  group('Models', () {
    test('TripRecord and AppNotification survive a map round-trip', () {
      const trip = TripRecord(
        id: 't',
        ownerUid: 'u',
        ownerEmail: 'o@example.com',
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
        sharedWithEmails: ['f@example.com'],
      );
      expect(TripRecord.fromMap(trip.toMap()).toMap(), trip.toMap());
      const note = AppNotification(
        id: 'n',
        title: 'Title',
        body: 'Body',
        site: 'Redwood Grove',
      );
      expect(AppNotification.fromMap(note.toMap()).title, 'Title');
    });
  });

  group('Wired UI (local mode)', () {
    setUpAll(() async {
      final loader = FontLoader('Roboto');
      loader.addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
      loader.addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
      loader.addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });

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

    testWidgets('signing up shows the real account name, not a sample', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        CampReady(key: UniqueKey(), initialRoute: '/signup'),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex-new@example.com');
      await tester.enterText(fields.at(2), 'campready123');
      await tap(tester, 'Create account');
      expect(find.text('Find your nearby outside'), findsOneWidget);
      await tap(tester, 'Allow location');
      await tap(tester, 'Allow location');
      // Profile shows the account created above.
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Profile'),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsWidgets);
      expect(find.text('alex-new@example.com'), findsWidgets);
      expect(find.text('John'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
