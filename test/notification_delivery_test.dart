// Notification delivery tests (local mode only — no Firebase project,
// no network). These pin the First Integrations messaging contract:
// a share notifies the invitee, a condition change notifies the owner
// and every invitee, and delivery is trip-scoped, so it works for
// invitees who sign up after being shared with and does not depend on
// a per-invitee account lookup.
import 'package:campready/app.dart';
import 'package:campready/services/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(CampReadyServices, AppUser, AppUser, TripRecord)> _sharedTrip({
  String ownerEmail = 'owner@example.com',
  String inviteeEmail = 'friend@example.com',
}) async {
  final services = CampReadyServices.local();
  final owner = await services.auth.signUp(
    email: ownerEmail,
    password: 'campready123',
    displayName: 'Owner',
  );
  await services.auth.signUp(
    email: inviteeEmail,
    password: 'campready123',
    displayName: 'Friend',
  );
  await services.auth.signIn(email: ownerEmail, password: 'campready123');
  final trip = await services.firestore.createTrip(
    TripRecord(
      id: 'trip_${owner.uid}_Redwood_Grove',
      ownerUid: owner.uid,
      ownerEmail: owner.email,
      site: 'Redwood Grove',
      dates: 'Oct 23–25, 2026',
    ),
  );
  final shared = await services.firestore.shareTrip(
    tripId: trip.id,
    email: inviteeEmail,
  );
  final invitee = services.store.findUser(inviteeEmail)!;
  return (services, owner, invitee, shared);
}

void main() {
  group('MessagingService delivery (local mode)', () {
    test('share notifies the invitee, not the owner', () async {
      final (services, owner, invitee, trip) = await _sharedTrip();
      final note = await services.messaging.notifyTripShared(
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        inviteeEmail: invitee.email,
        tripId: trip.id,
        site: 'Redwood Grove',
      );
      expect(note.title, 'You were invited to Redwood Grove');
      final inviteeNotes = await services.firestore.notifications(
        invitee.uid,
        email: invitee.email,
      );
      expect(
        inviteeNotes.map((n) => n.id),
        contains(note.id),
      );
      final ownerNotes = await services.firestore.notifications(
        owner.uid,
        email: owner.email,
      );
      expect(ownerNotes.map((n) => n.id), isNot(contains(note.id)));
    });

    test('condition change reaches owner once and invitee once', () async {
      final (services, owner, invitee, trip) = await _sharedTrip();
      final note = await services.messaging.notifyConditionChange(
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        tripId: trip.id,
        site: 'Redwood Grove',
        title: 'Redwood Grove: dates changed',
        body: 'Your trip dates are now Oct 30–Nov 1, 2026.',
        sharedWithEmails: [invitee.email],
      );
      final ownerNotes = await services.firestore.notifications(
        owner.uid,
        email: owner.email,
      );
      expect(ownerNotes.where((n) => n.id == note.id).length, 1);
      final inviteeNotes = await services.firestore.notifications(
        invitee.uid,
        email: invitee.email,
      );
      expect(inviteeNotes.where((n) => n.id == note.id).length, 1);
      // A second read does not duplicate either copy.
      expect(
        (await services.firestore.notifications(
          invitee.uid,
          email: invitee.email,
        )).where((n) => n.id == note.id).length,
        1,
      );
    });

    test('share before sign-up still delivers when the invitee joins', () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
        displayName: 'Owner',
      );
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: 'trip_${owner.uid}_Redwood_Grove',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
        ),
      );
      await services.firestore.shareTrip(
        tripId: trip.id,
        email: 'late@example.com',
      );
      await services.messaging.notifyTripShared(
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        inviteeEmail: 'late@example.com',
        tripId: trip.id,
        site: 'Redwood Grove',
      );
      // The invitee did not exist when shared with.
      expect(services.store.findUser('late@example.com'), isNull);
      final late = await services.auth.signUp(
        email: 'late@example.com',
        password: 'campready123',
        displayName: 'Late',
      );
      final state = DemoState(services: services);
      await state.loadAccount();
      expect(state.trips, contains('Redwood Grove'));
      expect(
        state.notifications.map((n) => n.title),
        contains('You were invited to Redwood Grove'),
      );
      expect(late.email, 'late@example.com');
    });

    test('mixed-case share is normalised and delivered', () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
        displayName: 'Owner',
      );
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: 'trip_mixed',
          ownerUid: owner.uid,
          ownerEmail: 'Owner@Example.COM',
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
        ),
      );
      final shared = await services.firestore.shareTrip(
        tripId: trip.id,
        email: 'Friend@Example.COM',
      );
      expect(shared.sharedWithEmails, ['friend@example.com']);
      expect(shared.ownerEmail, 'owner@example.com');
      await services.auth.signUp(
        email: 'friend@example.com',
        password: 'campready123',
        displayName: 'Friend',
      );
      final invitee = services.store.findUser('friend@example.com')!;
      expect(
        await services.firestore.tripsForUser(invitee.uid, invitee.email),
        hasLength(1),
      );
      await services.messaging.notifyTripShared(
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        inviteeEmail: 'Friend@Example.COM',
        tripId: trip.id,
        site: 'Redwood Grove',
      );
      expect(
        (await services.firestore.notifications(
          invitee.uid,
          email: invitee.email,
        )).map((n) => n.title),
        contains('You were invited to Redwood Grove'),
      );
    });

    test('marking a trip notification read is per-user', () async {
      final (services, owner, invitee, trip) = await _sharedTrip();
      final note = await services.messaging.notifyConditionChange(
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        tripId: trip.id,
        site: 'Redwood Grove',
        title: 'Redwood Grove: dates changed',
        body: 'Your trip dates are now Oct 30–Nov 1, 2026.',
        sharedWithEmails: [invitee.email],
      );
      await services.firestore.markNotificationRead(invitee.uid, note.id);
      final inviteeNotes = await services.firestore.notifications(
        invitee.uid,
        email: invitee.email,
      );
      expect(
        inviteeNotes.firstWhere((n) => n.id == note.id).read,
        isTrue,
      );
      // Still present (and still unread) for the owner.
      final ownerNotes = await services.firestore.notifications(
        owner.uid,
        email: owner.email,
      );
      expect(
        ownerNotes.firstWhere((n) => n.id == note.id).read,
        isFalse,
      );
    });

    test('tapped background message is recorded and emitted', () async {
      final services = CampReadyServices.local();
      final seen = <RemoteMessage>[];
      final sub = services.messaging.onMessageOpened.listen(seen.add);
      const message = RemoteMessage(
        messageId: 'msg-1',
        data: {'tripId': 'trip_1', 'site': 'Redwood Grove'},
        notification: RemoteNotification(
          title: 'Redwood Grove: dates changed',
          body: 'Your trip dates are now Oct 30–Nov 1, 2026.',
        ),
      );
      services.messaging.handleOpenedMessage(message);
      // Broadcast streams deliver asynchronously.
      await Future<void>.delayed(Duration.zero);
      expect(seen, [message]);
      expect(
        services.messaging.delivered.map((n) => n.id),
        contains('msg-1'),
      );
      expect(
        services.messaging.delivered.first.tripId,
        'trip_1',
      );
      await sub.cancel();
    });
  });

  group('FirestoreService guards (local mode)', () {
    test('creating the same trip twice throws and keeps shares', () async {
      final (services, owner, invitee, trip) = await _sharedTrip();
      await expectLater(
        services.firestore.createTrip(trip),
        throwsStateError,
      );
      expect(
        (await services.firestore.getTrip(trip.id))?.sharedWithEmails,
        [invitee.email],
      );
      expect(owner.uid, isNotEmpty);
    });

    test('email normalisation survives a map round-trip', () {
      const trip = TripRecord(
        id: 't',
        ownerUid: 'u',
        ownerEmail: 'Owner@Example.COM',
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
        sharedWithEmails: ['Friend@Example.COM', ' friend@example.com '],
      );
      final restored = TripRecord.fromMap(trip.toMap());
      expect(restored.ownerEmail, 'owner@example.com');
      expect(restored.sharedWithEmails, ['friend@example.com']);
    });

    test('stored timestamps parse from string, DateTime, or garbage', () {
      expect(parseStoredDateTime('2026-11-07T10:00:00.000'), isNotNull);
      expect(
        parseStoredDateTime(DateTime(2026, 11, 7)),
        DateTime(2026, 11, 7),
      );
      expect(parseStoredDateTime('not-a-date'), isNull);
      expect(parseStoredDateTime(null), isNull);
      expect(parseStoredDateTime(12345), isNull);
    });
  });

  group('Wired UI (local mode)', () {
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

    testWidgets('Send invitation notifies the invitee (UI action)', (
      tester,
    ) async {
      final (services, owner, invitee, trip) = await _sharedTrip();
      final state = DemoState(services: services);
      await state.loadAccount();
      expect(state.trips, contains('Redwood Grove'));
      await tester.pumpWidget(
        CampReady(initialState: state, initialRoute: '/share'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        invitee.email,
      );
      await tap(tester, 'Send invitation');
      expect(
        tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route,
        'shared',
      );
      expect(
        (await services.firestore.notifications(
          invitee.uid,
          email: invitee.email,
        )).map((n) => n.title),
        contains('You were invited to Redwood Grove'),
      );
      expect(trip.ownerUid, owner.uid);
    });

    testWidgets('date edit through the UI notifies the invitee', (
      tester,
    ) async {
      final (services, owner, invitee, _) = await _sharedTrip();
      final state = DemoState(services: services);
      await state.loadAccount();
      await tester.pumpWidget(
        CampReady(initialState: state, initialRoute: '/dates'),
      );
      await tester.pumpAndSettle();
      state.editingTrip = true;
      await tap(tester, 'October 30–November 1');
      await tap(tester, 'Use selected dates');
      expect(state.details['Redwood Grove']?.dates, 'Oct 30–Nov 1, 2026');
      expect(
        (await services.firestore.notifications(
          invitee.uid,
          email: invitee.email,
        )).map((n) => n.title),
        contains('Redwood Grove: dates changed'),
      );
      expect(owner.uid, isNotEmpty);
    });

    testWidgets('invitee sees the share notification on Alerts', (
      tester,
    ) async {
      final (services, owner, invitee, trip) = await _sharedTrip();
      await services.messaging.notifyTripShared(
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        inviteeEmail: invitee.email,
        tripId: trip.id,
        site: 'Redwood Grove',
      );
      await services.auth.signIn(email: invitee.email, password: 'campready123');
      final state = DemoState(services: services);
      await tester.pumpWidget(
        CampReady(initialState: state, initialRoute: '/alerts'),
      );
      await tester.pumpAndSettle();
      expect(state.notifications.map((n) => n.title), contains(
        'You were invited to Redwood Grove',
      ));
      expect(find.text('You were invited to Redwood Grove'), findsOneWidget);
    });

    testWidgets('Host accepts through the UI notifies the invitee', (
      tester,
    ) async {
      final (services, _, invitee, _) = await _sharedTrip();
      final state = DemoState(services: services);
      await state.loadAccount();
      await tester.pumpWidget(
        CampReady(initialState: state, initialRoute: '/booking-response'),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Host accepts');
      expect(
        (await services.firestore.notifications(
          invitee.uid,
          email: invitee.email,
        )).map((n) => n.title),
        contains('Redwood Grove: booking Accepted'),
      );
    });
  });
}
