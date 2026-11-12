import 'package:campready/models/stay.dart';
import 'package:campready/router.dart';
import 'package:campready/screens.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

/// Owner with one trip, shared with a friend who also shares one back.
Future<CampReadyServices> seeded() async {
  final services = CampReadyServices.local();
  final friend = await services.auth.signUp(
    email: 'friend@example.com',
    password: 'campready123',
  );
  await services.firestore.createTrip(
    TripRecord(
      id: TripRecord.idFor(friend.uid, 'Sunset Ridge'),
      ownerUid: friend.uid,
      ownerEmail: friend.email,
      site: 'Sunset Ridge',
      siteId: 'sunset-ridge',
      dates: 'Dec 4–6, 2026',
      stay: Stay(DateTime(2026, 12, 4), DateTime(2026, 12, 6)),
      sharedWithEmails: const ['owner@example.com'],
    ),
  );
  await services.auth.signOut();
  final owner = await services.auth.signUp(
    email: 'owner@example.com',
    password: 'campready123',
    displayName: 'Owner',
  );
  await services.firestore.createTrip(
    TripRecord(
      id: TripRecord.idFor(owner.uid, 'Redwood Grove'),
      ownerUid: owner.uid,
      ownerEmail: owner.email,
      site: 'Redwood Grove',
      siteId: 'redwood-grove',
      dates: 'Dec 11–13, 2026',
      stay: Stay(DateTime(2026, 12, 11), DateTime(2026, 12, 13)),
      downloadedDates: 'Dec 11–13, 2026',
    ),
  );
  await services.firestore.saveCampsite(
    owner.uid,
    const SavedCampsite(siteId: 'redwood-grove', name: 'Redwood Grove'),
  );
  return services;
}

const _prototypeText = [
  'Demo · Guide',
  'Simulate request failure',
  'Simulate send failure',
  'Simulate connection failure',
  'Prototype',
  'prototype',
  'Sample condition',
  'Connection scenarios',
  'Other date states',
  'View demo trip link',
  '9:41',
  'john.doe@example.com',
];

void main() {
  setUpAll(loadFonts);

  group('Every named route renders', () {
    for (final page in campPages) {
      testWidgets('/${page.route}', (tester) async {
        await pumpApp(tester, await seeded(), route: '/${page.route}');
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
        if (!showDemoBuild && demoRoutes.contains(page.route)) {
          expect(screenOf(tester), 'explore');
        }
        for (final text in _prototypeText) {
          expect(
            find.textContaining(text),
            findsNothing,
            reason: '"$text" is visible on /${page.route}',
          );
        }
      });
    }
  });

  group('Deep links', () {
    testWidgets('signed out, a trip link asks to sign in and comes back', (
      tester,
    ) async {
      final services = await seeded();
      final tripId = TripRecord.idFor(
        services.auth.currentUser!.uid,
        'Redwood Grove',
      );
      await services.auth.signOut();
      await pumpApp(tester, services, route: '/trips/$tripId');
      expect(screenOf(tester), 'authgate');
      await tap(tester, 'Sign in');
      await enter(tester, 'Email', 'owner@example.com');
      await enter(tester, 'Password', 'campready123');
      await tap(tester, 'Sign in');
      expect(screenOf(tester), 'trip');
      expect(tripOf(tester), tripId);
    });

    testWidgets('an unknown trip shows that it is no longer available', (
      tester,
    ) async {
      await pumpApp(tester, await seeded(), route: '/trips/missing-trip');
      expect(screenOf(tester), 'this-trip-is-no-longer-available');
    });

    testWidgets('an invitee opening owner screens sees the invitation', (
      tester,
    ) async {
      final services = await seeded();
      final friend = services.store.findUser('friend@example.com')!;
      await pumpApp(
        tester,
        services,
        route: '/trips/${TripRecord.idFor(friend.uid, 'Sunset Ridge')}/share',
      );
      expect(screenOf(tester), 'you-re-invited');
      expect(find.text('Accept invitation'), findsOneWidget);
    });

    testWidgets('an unknown campsite falls back to Explore', (tester) async {
      await pumpApp(tester, await seeded(), route: '/campsite/yosemite');
      expect(screenOf(tester), 'explore');
    });

    testWidgets('old flat paths still open the right screen', (tester) async {
      await pumpApp(tester, await seeded(), route: '/ridge');
      expect(screenOf(tester), 'detail');
      expect(siteOf(tester), 'sunset-ridge');
    });
  });
}
