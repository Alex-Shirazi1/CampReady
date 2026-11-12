import 'dart:async';

import 'package:campready/repositories/auth_repository.dart';
import 'package:campready/repositories/campsite_repository.dart';
import 'package:campready/repositories/location_repository.dart';
import 'package:campready/repositories/notification_repository.dart';
import 'package:campready/repositories/photo_repository.dart';
import 'package:campready/repositories/profile_repository.dart';
import 'package:campready/repositories/trip_repository.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirestoreService {}

class MockMessaging extends Mock implements MessagingService {}

class MockAuth extends Mock implements AuthService {}

class MockGeolocator extends Mock implements GeolocatorPlatform {}

void main() {
  const owner = AppUser(uid: 'o1', email: 'owner@example.com');
  const friend = AppUser(uid: 'f1', email: 'friend@example.com');
  const trip = TripRecord(
    id: 'trip_o1_Redwood_Grove',
    ownerUid: 'o1',
    ownerEmail: 'owner@example.com',
    site: 'Redwood Grove',
    dates: 'Dec 12–14, 2026',
    sharedWithEmails: ['friend@example.com', 'late@example.com'],
  );
  late MockFirestore firestore;
  late MockMessaging messaging;

  photoTests();
  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(CameraDevice.front);
    registerFallbackValue(owner);
    registerFallbackValue(trip);
    registerFallbackValue(const SavedCampsite(siteId: '', name: ''));
  });
  setUp(() {
    firestore = MockFirestore();
    messaging = MockMessaging();
  });

  group('TripRepository', () {
    test('owner view lists answers from current invitees only', () async {
      when(() => firestore.tripsForUser('o1', 'owner@example.com'))
          .thenAnswer((_) async => [trip]);
      when(() => firestore.invitationResponses(trip.id)).thenAnswer(
        (_) async => [
          {'email': 'friend@example.com', 'status': 'accepted'},
          {'email': 'removed@example.com', 'status': 'accepted'},
        ],
      );
      final views = await TripRepository(firestore, messaging).tripsFor(owner);
      expect(views.single.isOwner, isTrue);
      expect(views.single.responses, const [
        InviteResponse('friend@example.com', 'accepted'),
      ]);
      expect(
        views.single.people,
        'friend@example.com: accepted\nlate@example.com: pending',
      );
    });

    test('invitee who declined no longer sees the trip', () async {
      when(() => firestore.tripsForUser('f1', 'friend@example.com'))
          .thenAnswer((_) async => [trip]);
      when(() => firestore.invitationResponse(trip.id, 'f1'))
          .thenAnswer((_) async => {'status': 'declined'});
      expect(
        await TripRepository(firestore, messaging).tripsFor(friend),
        isEmpty,
      );
    });

    test('a denied response read still shows the invitation', () async {
      when(() => firestore.tripsForUser('f1', 'friend@example.com'))
          .thenAnswer((_) async => [trip]);
      when(() => firestore.invitationResponse(trip.id, 'f1'))
          .thenThrow(Exception('permission-denied'));
      final views = await TripRepository(firestore, messaging).tripsFor(friend);
      expect(views.single.isOwner, isFalse);
      expect(views.single.people, 'Invitation pending');
    });

    test('share notice goes to the invitee through the trip', () async {
      when(
        () => messaging.notifyTripShared(
          ownerUid: any(named: 'ownerUid'),
          ownerEmail: any(named: 'ownerEmail'),
          inviteeEmail: any(named: 'inviteeEmail'),
          tripId: any(named: 'tripId'),
          site: any(named: 'site'),
        ),
      ).thenAnswer(
        (_) async => const AppNotification(id: 'n', title: 't', body: 'b'),
      );
      await TripRepository(
        firestore,
        messaging,
      ).notifyShared(trip, 'friend@example.com');
      verify(
        () => messaging.notifyTripShared(
          ownerUid: 'o1',
          ownerEmail: 'owner@example.com',
          inviteeEmail: 'friend@example.com',
          tripId: trip.id,
          site: 'Redwood Grove',
        ),
      ).called(1);
    });
  });

  group('CampsiteRepository', () {
    test('saved ids accept older name-keyed saves', () async {
      when(() => firestore.savedCampsites('o1')).thenAnswer(
        (_) async => const [
          SavedCampsite(siteId: 'Redwood Grove', name: 'Redwood Grove'),
          SavedCampsite(siteId: 'sunset-ridge', name: 'Sunset Ridge'),
          SavedCampsite(siteId: 'gone', name: 'Removed site'),
        ],
      );
      expect(await CampsiteRepository(firestore).savedIds('o1'), {
        'redwood-grove',
        'sunset-ridge',
      });
    });

    test('remove also clears an older name-keyed save', () async {
      when(() => firestore.removeCampsite(any(), any()))
          .thenAnswer((_) async {});
      await CampsiteRepository(firestore).remove('o1', campsiteCatalog.first);
      verify(() => firestore.removeCampsite('o1', 'redwood-grove')).called(1);
      verify(() => firestore.removeCampsite('o1', 'Redwood Grove')).called(1);
    });

    test('search matches name or area, case-insensitive', () {
      final repo = CampsiteRepository(firestore);
      expect(repo.search('SANTA').single.id, 'redwood-grove');
      expect(repo.search('ridge').single.id, 'sunset-ridge');
      expect(repo.search('  '), campsiteCatalog);
      expect(repo.search('yosemite'), isEmpty);
    });
  });

  group('AuthRepository', () {
    late MockAuth auth;
    setUp(() => auth = MockAuth());

    test('sign out still signs out when push cleanup fails', () async {
      when(() => messaging.detachUser()).thenThrow(Exception('offline'));
      when(() => auth.signOut()).thenAnswer((_) async {});
      await AuthRepository(auth, firestore, messaging).signOut();
      verify(() => auth.signOut()).called(1);
    });

    test('local mode emits the current user first', () async {
      when(() => auth.useFirebase).thenReturn(false);
      when(() => auth.currentUser).thenReturn(owner);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      expect(
        await AuthRepository(auth, firestore, messaging).userChanges.first,
        owner,
      );
    });

    test('a new display name is saved to the profile', () async {
      final renamed = owner.copyWith(displayName: 'Atie');
      when(() => auth.updateDisplayName('Atie'))
          .thenAnswer((_) async => renamed);
      when(() => firestore.saveUserProfile(renamed)).thenAnswer((_) async {});
      expect(
        await AuthRepository(
          auth,
          firestore,
          messaging,
        ).updateDisplayName('Atie'),
        renamed,
      );
      verify(() => firestore.saveUserProfile(renamed)).called(1);
    });
  });

  group('NotificationRepository', () {
    test('load keeps updates for visible trips only', () async {
      when(() => firestore.notifications('o1', email: 'owner@example.com'))
          .thenAnswer(
            (_) async => const [
              AppNotification(id: 'a', title: 'a', body: '', tripId: 't1'),
              AppNotification(id: 'b', title: 'b', body: '', tripId: 'gone'),
              AppNotification(id: 'c', title: 'c', body: ''),
            ],
          );
      final notes = await NotificationRepository(
        messaging,
        firestore,
      ).load(owner, tripIds: {'t1'});
      expect(notes.map((n) => n.id), ['a', 'c']);
    });

    test('enable push reports a denied permission', () async {
      when(() => messaging.requestPermission()).thenAnswer((_) async => false);
      when(() => messaging.status).thenReturn('Push permission denied');
      expect(
        () => NotificationRepository(messaging, firestore).enablePush('o1'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Push permission denied',
          ),
        ),
      );
    });

    test('enable push fails when no token is issued', () async {
      when(() => messaging.requestPermission()).thenAnswer((_) async => true);
      when(() => messaging.getToken('o1')).thenAnswer((_) async => null);
      expect(
        () => NotificationRepository(messaging, firestore).enablePush('o1'),
        throwsStateError,
      );
    });
  });

  group('ProfileRepository', () {
    test('reads plan, alerts and photo from the user document', () async {
      when(() => firestore.userSettings('o1')).thenAnswer(
        (_) async => {'plan': 'plus', 'alertsEnabled': false, 'photo': 'x'},
      );
      expect(
        await ProfileRepository(firestore).load('o1'),
        const ProfileSettings(plus: true, alertsEnabled: false, photo: 'x'),
      );
    });

    test('defaults to free with alerts on', () async {
      when(() => firestore.userSettings('o1')).thenAnswer((_) async => {});
      expect(
        await ProfileRepository(firestore).load('o1'),
        const ProfileSettings(),
      );
    });
  });

  group('LocationRepository', () {
    late MockGeolocator geo;
    setUp(() => geo = MockGeolocator());

    test('location services off', () async {
      when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => false);
      final result = await LocationRepository(geolocator: geo)
          .currentPosition();
      expect(result.status, LocationStatus.serviceDisabled);
      verifyNever(() => geo.requestPermission());
    });

    test('denied after asking', () async {
      when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => geo.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => geo.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      expect(
        (await LocationRepository(geolocator: geo).currentPosition()).status,
        LocationStatus.denied,
      );
    });

    test('permanently denied does not prompt again', () async {
      when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => geo.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);
      expect(
        (await LocationRepository(geolocator: geo).currentPosition()).status,
        LocationStatus.deniedForever,
      );
      verifyNever(() => geo.requestPermission());
    });

    test('granted returns the position', () async {
      when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => geo.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => geo.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer(
        (_) async => Position(
          latitude: 37.35,
          longitude: -121.94,
          timestamp: DateTime(2026),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      final result = await LocationRepository(geolocator: geo)
          .currentPosition();
      expect(result.status, LocationStatus.granted);
      expect(result.latitude, 37.35);
    });

    test('a GPS timeout is reported as unavailable', () async {
      when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => geo.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
      when(
        () => geo.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(Exception('timeout'));
      expect(
        (await LocationRepository(geolocator: geo).currentPosition()).status,
        LocationStatus.unavailable,
      );
    });

    test('a slow GPS fix falls back to the last known position', () async {
      when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => geo.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => geo.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(TimeoutException('no fix'));
      when(
        () => geo.getLastKnownPosition(
          forceLocationManager: any(named: 'forceLocationManager'),
        ),
      ).thenAnswer(
        (_) async => Position(
          latitude: 37.1,
          longitude: -122.1,
          timestamp: DateTime(2026),
          accuracy: 50,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      final result = await LocationRepository(geolocator: geo)
          .currentPosition();
      expect(result.status, LocationStatus.granted);
      expect(result.latitude, 37.1);
    });

    test('distance is converted to miles', () {
      when(() => geo.distanceBetween(any(), any(), any(), any()))
          .thenReturn(1609.344 * 3);
      expect(LocationRepository(geolocator: geo).milesBetween(0, 0, 1, 1), 3);
    });
  });
}

class MockPicker extends Mock implements ImagePicker {}

void photoTests() {
  group('PhotoRepository', () {
    late MockPicker picker;
    setUp(() => picker = MockPicker());

    void answer(Future<XFile?> Function() result) => when(
      () => picker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
        preferredCameraDevice: any(named: 'preferredCameraDevice'),
      ),
    ).thenAnswer((_) => result());

    test('a small photo is returned as base64', () async {
      answer(() async => XFile.fromData(Uint8List.fromList([1, 2, 3])));
      expect(await PhotoRepository(picker: picker).pick(camera: true), 'AQID');
      verify(
        () => picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 320,
          maxHeight: 320,
          imageQuality: 70,
          preferredCameraDevice: CameraDevice.front,
        ),
      ).called(1);
    });

    test('cancelling returns null', () async {
      answer(() async => null);
      expect(await PhotoRepository(picker: picker).pick(camera: false), isNull);
    });

    test('denied camera permission gives a clear message', () async {
      answer(() async => throw PlatformException(code: 'camera_access_denied'));
      expect(
        () => PhotoRepository(picker: picker).pick(camera: true),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Camera access is off'),
          ),
        ),
      );
    });

    test('photos over 200 KB are refused', () async {
      answer(
        () async => XFile.fromData(Uint8List(PhotoRepository.maxBytes + 1)),
      );
      expect(
        () => PhotoRepository(picker: picker).pick(camera: false),
        throwsStateError,
      );
    });
  });
}
