import 'package:campready/models/stay.dart';
import 'package:campready/app.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('restored account loads saved campsites and trips', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    final user = await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    await services.firestore.saveCampsite(
      user.uid,
      const SavedCampsite(siteId: 'Redwood Grove', name: 'Redwood Grove'),
    );
    await services.firestore.createTrip(
      TripRecord(
        id: 'persisted-trip',
        ownerUid: user.uid,
        ownerEmail: user.email,
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
      ),
    );
    final state = DemoState(services: services);
    await tester.pumpWidget(
      CampReady(initialState: state, initialRoute: '/trips'),
    );
    await tester.pumpAndSettle();
    expect(state.savedCampsiteIds, contains('Redwood Grove'));
    expect(state.trips, contains('Redwood Grove'));
    expect(state.details['Redwood Grove']?.dates, 'Oct 23–25, 2026');
  });

  testWidgets('sign out clears private state before another account signs in', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    final state = DemoState(services: services)
      ..savedCampsiteIds.add('Redwood Grove')
      ..trips.add('Redwood Grove')
      ..plus = true;
    await tester.pumpWidget(
      CampReady(initialState: state, initialRoute: '/signout'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(state.trips, isEmpty);
    expect(state.savedCampsiteIds, isEmpty);
    expect(state.plus, isFalse);
    expect(services.auth.currentUser, isNull);
  });

  test(
    'accepted invitation restores joined view and updated owner dates',
    () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: 'shared-trip',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
        ),
      );
      final shared = await services.firestore.shareTrip(
        tripId: trip.id,
        email: 'friend@example.com',
      );
      final friend = await services.auth.signUp(
        email: 'friend@example.com',
        password: 'campready123',
      );
      await services.firestore.respondToInvitation(shared, friend, 'accepted');
      await services.firestore.updateTrip(
        trip.copyWith(
          stay: Stay(DateTime(2026, 10, 30), DateTime(2026, 11, 1)),
        ),
      );
      final state = DemoState(services: services);
      await state.loadAccount();
      expect(state.records['Redwood Grove']?.id, trip.id);
      expect(state.details['Redwood Grove']?.invitation, 'You joined the trip');
      expect(state.details['Redwood Grove']?.dates, 'Oct 30–Nov 1, 2026');
      expect((await services.firestore.getTrip(trip.id))?.sharedWithEmails, [
        'friend@example.com',
      ]);
    },
  );

  test(
    'declining hides a shared trip without changing the owner plan',
    () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: 'shared-trip',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
        ),
      );
      final shared = await services.firestore.shareTrip(
        tripId: trip.id,
        email: 'friend@example.com',
      );
      final friend = await services.auth.signUp(
        email: 'friend@example.com',
        password: 'campready123',
      );
      await services.firestore.respondToInvitation(shared, friend, 'declined');
      final state = DemoState(services: services);
      await state.loadAccount();
      expect(state.trips, isEmpty);
      await services.auth.signIn(email: owner.email, password: 'campready123');
      await state.loadAccount();
      expect(state.trips, {'Redwood Grove'});
      expect(
        state.details['Redwood Grove']?.invitation,
        'friend@example.com: declined',
      );
      expect(state.details['Redwood Grove']?.dates, trip.dates);
    },
  );

  test(
    'revoked invitation cannot be accepted and reinvite starts pending',
    () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: 'shared-trip',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
        ),
      );
      final shared = await services.firestore.shareTrip(
        tripId: trip.id,
        email: 'friend@example.com',
      );
      final friend = await services.auth.signUp(
        email: 'friend@example.com',
        password: 'campready123',
      );
      await services.firestore.respondToInvitation(shared, friend, 'declined');
      await services.firestore.revokeInvitations(shared);
      await expectLater(
        services.firestore.respondToInvitation(shared, friend, 'accepted'),
        throwsStateError,
      );
      expect(
        await services.firestore.tripsForUser(friend.uid, friend.email),
        isEmpty,
      );
      await services.firestore.shareTrip(
        tripId: trip.id,
        email: 'friend@example.com',
      );
      final state = DemoState(services: services);
      await state.loadAccount();
      expect(state.trips, {'Redwood Grove'});
      expect(
        state.details['Redwood Grove']?.invitation,
        'Invitation pending · friend@example.com',
      );
    },
  );

  test(
    'account switch during loading does not restore the old account data',
    () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      await services.firestore.saveCampsite(
        owner.uid,
        const SavedCampsite(siteId: 'Redwood Grove', name: 'Redwood Grove'),
      );
      final state = DemoState(services: services);
      final oldLoad = state.loadAccount();
      final other = await services.auth.signUp(
        email: 'other@example.com',
        password: 'campready123',
      );
      final newLoad = state.loadAccount();
      await Future.wait([oldLoad, newLoad]);
      expect(state.accountUid, other.uid);
      expect(state.email, other.email);
      expect(state.savedCampsiteIds, isEmpty);
      expect(state.trips, isEmpty);
    },
  );

  test(
    'duplicate campsite trips are reported without overwriting either record',
    () async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      final friend = await services.auth.signUp(
        email: 'friend@example.com',
        password: 'campready123',
      );
      for (final user in [owner, friend]) {
        await services.firestore.createTrip(
          TripRecord(
            id: 'trip-${user.uid}',
            ownerUid: user.uid,
            ownerEmail: user.email,
            site: 'Redwood Grove',
            dates: user == owner ? 'Oct 23–25, 2026' : 'Oct 30–Nov 1, 2026',
            sharedWithEmails: user == owner ? [friend.email] : [],
          ),
        );
      }
      final state = DemoState(services: services);
      await state.loadAccount();
      expect(state.syncError, contains('More than one trip'));
      expect(state.records, isEmpty);
      expect(
        (await services.firestore.getTrip('trip-${owner.uid}'))?.dates,
        'Oct 23–25, 2026',
      );
      expect(
        (await services.firestore.getTrip('trip-${friend.uid}'))?.dates,
        'Oct 30–Nov 1, 2026',
      );
    },
  );

  testWidgets(
    'saved disabled notification preference survives account restoration',
    (tester) async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      await services.firestore.createTrip(
        TripRecord(
          id: 'quiet-trip',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
          alertsEnabled: true,
        ),
      );
      await services.firestore.saveAlertPreference(owner.uid, false);
      final state = DemoState(services: services);
      await tester.pumpWidget(
        CampReady(initialState: state, initialRoute: '/preferences'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await tester.pumpWidget(
        CampReady(
          key: UniqueKey(),
          initialState: state,
          initialRoute: '/ridge',
        ),
      );
      await tester.pumpAndSettle();
      expect(state.site, 'Sunset Ridge');
      expect(state.alerts, isFalse);
    },
  );

  testWidgets('recipient cannot edit dates through an owner trip route', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    final owner = await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    final trip = await services.firestore.createTrip(
      TripRecord(
        id: 'shared-trip',
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
        sharedWithEmails: ['friend@example.com'],
      ),
    );
    await services.auth.signUp(
      email: 'friend@example.com',
      password: 'campready123',
    );
    final state = DemoState(services: services);
    await tester.pumpWidget(
      CampReady(initialState: state, initialRoute: '/trip'),
    );
    await tester.pumpAndSettle();
    final edit = find.text('Edit dates');
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Shared trips are view-only. Ask the owner to change this trip.',
      ),
      findsOneWidget,
    );
    expect((await services.firestore.getTrip(trip.id))?.dates, trip.dates);
  });

  testWidgets(
    'failed date update preserves old plan and does not show success',
    (tester) async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: 'removed-trip',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
        ),
      );
      final state = DemoState(services: services);
      await tester.pumpWidget(
        CampReady(initialState: state, initialRoute: '/dates'),
      );
      await tester.pumpAndSettle();
      state.editingTrip = true;
      await services.firestore.deleteTrip(trip.id);
      await tester.tap(find.text('October 30–November 1'));
      await tester.pumpAndSettle();
      final save = find.text('Use selected dates');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('This trip was removed.'), findsOneWidget);
      expect(
        tester
            .widget<DesignScreen>(find.byType(DesignScreen).last)
            .screen
            .route,
        'dates',
      );
      expect(state.details['Redwood Grove']?.dates, trip.dates);
      expect(await services.firestore.getTrip(trip.id), isNull);
    },
  );

  test('resending a declined invitation resets it without revoking accepted invitations', () async {
    final services = CampReadyServices.local();
    final owner = await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    final trip = await services.firestore.createTrip(
      TripRecord(
        id: 'shared-trip',
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
      ),
    );
    final shared = await services.firestore.shareTrip(
      tripId: trip.id,
      email: 'friend@example.com',
    );
    final friend = await services.auth.signUp(
      email: 'friend@example.com',
      password: 'campready123',
    );
    await services.firestore.respondToInvitation(shared, friend, 'declined');
    await services.firestore.shareTrip(
      tripId: trip.id,
      email: 'friend@example.com',
    );
    final state = DemoState(services: services);
    await state.loadAccount();
    expect(state.trips, {'Redwood Grove'});
    expect(
      state.details['Redwood Grove']?.invitation,
      'Invitation pending · friend@example.com',
    );
    await services.firestore.respondToInvitation(shared, friend, 'accepted');
    await services.firestore.shareTrip(
      tripId: trip.id,
      email: 'friend@example.com',
    );
    await state.loadAccount();
    expect(state.details['Redwood Grove']?.invitation, 'You joined the trip');
    expect((await services.firestore.getTrip(trip.id))?.sharedWithEmails, [
      friend.email,
    ]);
  });

  testWidgets('Saved tab shows saved Redwood while Sunset is selected', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    final user = await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    await services.firestore.saveCampsite(
      user.uid,
      const SavedCampsite(siteId: 'Redwood Grove', name: 'Redwood Grove'),
    );
    final state = DemoState(services: services)..site = 'Sunset Ridge';
    await tester.pumpWidget(
      CampReady(initialState: state, initialRoute: '/profile'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route,
      'saved',
    );
    expect(find.text('Redwood Grove'), findsOneWidget);
    expect(find.text('1 saved campsite'), findsOneWidget);
    expect(find.text(r'$65 / night'), findsOneWidget);
    expect(find.text('Sunset Ridge'), findsNothing);
    final card = find.text('Redwood Grove');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route,
      'detail',
    );
    expect(state.site, 'Redwood Grove');
  });

  testWidgets('removing one saved campsite preserves and opens the other', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    final user = await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    for (final site in ['Redwood Grove', 'Sunset Ridge']) {
      await services.firestore.saveCampsite(
        user.uid,
        SavedCampsite(siteId: site, name: site),
      );
    }
    final state = DemoState(services: services)..site = 'Sunset Ridge';
    await tester.pumpWidget(
      CampReady(initialState: state, initialRoute: '/saved'),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 saved campsites'), findsOneWidget);
    expect(find.text('Redwood Grove'), findsOneWidget);
    expect(find.text(r'$65 / night'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sunset Ridge'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sunset Ridge'), findsOneWidget);
    expect(find.text(r'$55 / night'), findsOneWidget);
    final remove = find.text('Remove Redwood Grove');
    await tester.scrollUntilVisible(
      remove,
      -220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(state.savedCampsiteIds, {'Sunset Ridge'});
    expect(
      (await services.firestore.savedCampsites(user.uid))
          .map((site) => site.siteId),
      ['Sunset Ridge'],
    );
    expect(find.text('1 saved campsite'), findsOneWidget);
    expect(find.text('Redwood Grove'), findsNothing);
    expect(find.text('Sunset Ridge'), findsOneWidget);
    final card = find.text('Sunset Ridge');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route,
      'ridge',
    );
    expect(state.site, 'Sunset Ridge');
  });

  testWidgets(
    'recipient saves own notification preference without changing owner trip',
    (tester) async {
      final services = CampReadyServices.local();
      final owner = await services.auth.signUp(
        email: 'owner@example.com',
        password: 'campready123',
      );
      final trip = await services.firestore.createTrip(
        TripRecord(
          id: 'shared-trip',
          ownerUid: owner.uid,
          ownerEmail: owner.email,
          site: 'Redwood Grove',
          dates: 'Oct 23–25, 2026',
          sharedWithEmails: ['friend@example.com'],
        ),
      );
      final friend = await services.auth.signUp(
        email: 'friend@example.com',
        password: 'campready123',
      );
      final state = DemoState(services: services);
      await tester.pumpWidget(
        CampReady(initialState: state, initialRoute: '/preferences'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final save = find.text('Save preferences');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(state.alerts, isFalse);
      expect(await services.firestore.alertPreference(friend.uid), isFalse);
      expect(await services.firestore.alertPreference(owner.uid), isTrue);
      expect(
        (await services.firestore.getTrip(trip.id))?.toMap(),
        trip.toMap(),
      );
      await services.firestore.saveUserProfile(friend);
      expect(await services.firestore.alertPreference(friend.uid), isFalse);
    },
  );

  testWidgets('People on this trip refreshes a remote invitation response', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    final owner = await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    final trip = await services.firestore.createTrip(
      TripRecord(
        id: 'shared-trip',
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
        sharedWithEmails: ['friend@example.com'],
      ),
    );
    final friend = await services.auth.signUp(
      email: 'friend@example.com',
      password: 'campready123',
    );
    await services.firestore.respondToInvitation(trip, friend, 'accepted');
    await services.auth.signIn(email: owner.email, password: 'campready123');
    final state = DemoState(services: services);
    await tester.pumpWidget(
      CampReady(initialState: state, initialRoute: '/shared'),
    );
    await tester.pumpAndSettle();
    expect(
      state.details['Redwood Grove']?.invitation,
      'friend@example.com: accepted',
    );
    await services.firestore.respondToInvitation(trip, friend, 'declined');
    expect(
      state.details['Redwood Grove']?.invitation,
      'friend@example.com: accepted',
    );
    final people = find.text('People on this trip');
    await tester.ensureVisible(people);
    await tester.pumpAndSettle();
    await tester.tap(people);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route,
      'your-camping-group',
    );
    expect(find.text('friend@example.com: declined'), findsOneWidget);
    expect(find.text('friend@example.com: accepted'), findsNothing);
    expect(
      state.details['Redwood Grove']?.invitation,
      'friend@example.com: declined',
    );
  });

  testWidgets('recipient refresh recovers an invitation resent after decline', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    final owner = await services.auth.signUp(
      email: 'owner@example.com',
      password: 'campready123',
    );
    final trip = await services.firestore.createTrip(
      TripRecord(
        id: 'shared-trip',
        ownerUid: owner.uid,
        ownerEmail: owner.email,
        site: 'Redwood Grove',
        dates: 'Oct 23–25, 2026',
        sharedWithEmails: ['friend@example.com'],
      ),
    );
    final friend = await services.auth.signUp(
      email: 'friend@example.com',
      password: 'campready123',
    );
    await services.firestore.respondToInvitation(trip, friend, 'declined');
    final state = DemoState(services: services);
    await tester.pumpWidget(
      CampReady(initialState: state, initialRoute: '/you-re-invited'),
    );
    await tester.pumpAndSettle();
    expect(state.trips, isEmpty);
    await services.firestore.shareTrip(tripId: trip.id, email: friend.email);
    final refresh = find.text('Refresh shared plan');
    await tester.ensureVisible(refresh);
    await tester.pumpAndSettle();
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(
      tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route,
      'you-re-invited',
    );
    expect(state.trips, {'Redwood Grove'});
    expect(
      state.details['Redwood Grove']?.invitation,
      'Invitation pending · friend@example.com',
    );
    expect(find.text('Shared plan refreshed.'), findsOneWidget);
  });
}
