import 'package:bloc_test/bloc_test.dart';
import 'package:campready/blocs/explore/explore_cubit.dart';
import 'package:campready/blocs/profile/profile_cubit.dart';
import 'package:campready/blocs/saved/saved_cubit.dart';
import 'package:campready/models/campsite.dart';
import 'package:campready/repositories/campsite_repository.dart';
import 'package:campready/repositories/location_repository.dart';
import 'package:campready/repositories/notification_repository.dart';
import 'package:campready/repositories/profile_repository.dart';
import 'package:campready/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCampsiteRepository extends Mock implements CampsiteRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  final redwood = campsiteCatalog.first;
  final sunset = campsiteCatalog.last;
  late MockCampsiteRepository sites;
  late MockLocationRepository location;

  setUpAll(() => registerFallbackValue(redwood));
  setUp(() {
    sites = MockCampsiteRepository();
    location = MockLocationRepository();
  });

  group('ExploreCubit', () {
    final catalog = CampsiteRepository(CampReadyServices.local().firestore);
    blocTest<ExploreCubit, ExploreState>(
      'search narrows the list by name or area',
      build: () => ExploreCubit(catalog, location),
      act: (c) => c.search('boulder'),
      expect: () => [
        ExploreState(query: 'boulder', results: [sunset]),
      ],
    );

    blocTest<ExploreCubit, ExploreState>(
      'GPS position sorts campsites nearest first',
      setUp: () {
        when(() => location.currentPosition()).thenAnswer(
          (_) async => const LocationResult(
            LocationStatus.granted,
            latitude: 37.13,
            longitude: -122.12,
          ),
        );
        when(() => location.milesBetween(any(), any(), any(), any()))
            .thenAnswer((i) {
              final lat = i.positionalArguments[2] as double;
              return lat == sunset.latitude ? 0.4 : 7.2;
            });
      },
      build: () => ExploreCubit(catalog, location),
      act: (c) => c.locate(),
      expect: () => [
        ExploreState(
          results: campsiteCatalog,
          location: LocationStatus.locating,
        ),
        ExploreState(
          results: [sunset, redwood],
          location: LocationStatus.granted,
          distances: {redwood.id: 7.2, sunset.id: 0.4},
        ),
      ],
      verify: (c) {
        expect(c.state.distanceLabel(sunset.id), '0.4 mi away');
        expect(c.state.distanceLabel(redwood.id), '7.2 mi away');
      },
    );

    for (final status in [
      LocationStatus.denied,
      LocationStatus.deniedForever,
      LocationStatus.serviceDisabled,
      LocationStatus.unavailable,
    ]) {
      blocTest<ExploreCubit, ExploreState>(
        '${status.name} falls back without distances',
        setUp: () =>
            when(() => location.currentPosition())
                .thenAnswer((_) async => LocationResult(status)),
        build: () => ExploreCubit(catalog, location),
        act: (c) => c.locate(),
        expect: () => [
          ExploreState(
            results: campsiteCatalog,
            location: LocationStatus.locating,
          ),
          ExploreState(results: campsiteCatalog, location: status),
        ],
      );
    }

    test('filters match site type, guests, budget and pets', () {
      final cubit = ExploreCubit(catalog, location);
      expect(cubit.matches, [redwood]);
      cubit.setFilters(
        const CampsiteFilters(
          siteType: 'RV',
          travelers: 4,
          petsRequired: false,
        ),
      );
      expect(cubit.matches, [sunset]);
      cubit.setFilters(cubit.state.filters.copyWith(maxPrice: () => 55));
      expect(cubit.matches, isEmpty);
      cubit.resetFilters();
      expect(cubit.state.filters, const CampsiteFilters());
    });
  });

  group('SavedCubit', () {
    blocTest<SavedCubit, SavedState>(
      'load reads saved ids',
      setUp: () =>
          when(() => sites.savedIds('u1'))
              .thenAnswer((_) async => {redwood.id}),
      build: () => SavedCubit(sites),
      act: (c) => c.load('u1'),
      expect: () => [
        const SavedState(status: SavedStatus.loading),
        SavedState(status: SavedStatus.loaded, ids: {redwood.id}),
      ],
    );

    blocTest<SavedCubit, SavedState>(
      'save and remove only change the list after the write',
      setUp: () {
        when(() => sites.save('u1', any())).thenAnswer((_) async {});
        when(() => sites.remove('u1', any())).thenAnswer((_) async {});
      },
      build: () => SavedCubit(sites),
      act: (c) async {
        await c.save('u1', redwood);
        await c.remove('u1', redwood);
      },
      expect: () => [
        SavedState(ids: {redwood.id}),
        const SavedState(ids: {}),
      ],
    );

    blocTest<SavedCubit, SavedState>(
      'a failed save does not show the campsite as saved',
      setUp: () =>
          when(() => sites.save('u1', any())).thenThrow(Exception('x')),
      build: () => SavedCubit(sites),
      act: (c) => c.save('u1', redwood),
      errors: () => [isA<Exception>()],
      expect: () => <SavedState>[],
    );
  });

  group('ProfileCubit', () {
    late MockProfileRepository profiles;
    late MockNotificationRepository notes;
    setUp(() {
      profiles = MockProfileRepository();
      notes = MockNotificationRepository();
      when(() => notes.enablePush(any())).thenAnswer((_) async {});
    });

    blocTest<ProfileCubit, ProfileState>(
      'load reads plan and alert preference',
      setUp: () => when(() => profiles.load('u1')).thenAnswer(
        (_) async => const ProfileSettings(plus: true, alertsEnabled: false),
      ),
      build: () => ProfileCubit(profiles, notes),
      act: (c) => c.load('u1'),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(
          status: ProfileStatus.ready,
          settings: ProfileSettings(plus: true, alertsEnabled: false),
        ),
      ],
      verify: (_) => verifyNever(() => notes.enablePush(any())),
    );

    blocTest<ProfileCubit, ProfileState>(
      'load with alerts on registers this device for push',
      setUp: () =>
          when(() => profiles.load('u1'))
              .thenAnswer((_) async => const ProfileSettings()),
      build: () => ProfileCubit(profiles, notes),
      act: (c) => c.load('u1'),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(status: ProfileStatus.ready),
      ],
      verify: (_) => verify(() => notes.enablePush('u1')).called(1),
    );

    blocTest<ProfileCubit, ProfileState>(
      'load still works when push is denied',
      setUp: () {
        when(() => profiles.load('u1'))
            .thenAnswer((_) async => const ProfileSettings());
        when(() => notes.enablePush('u1'))
            .thenThrow(StateError('Push permission denied'));
      },
      build: () => ProfileCubit(profiles, notes),
      act: (c) => c.load('u1'),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(status: ProfileStatus.ready),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'turning alerts off removes the push token',
      setUp: () {
        when(() => profiles.setAlerts('u1', false)).thenAnswer((_) async {});
        when(() => notes.disablePush()).thenAnswer((_) async {});
      },
      build: () => ProfileCubit(profiles, notes),
      act: (c) => c.saveAlerts('u1', false),
      expect: () => [
        const ProfileState(settings: ProfileSettings(alertsEnabled: false)),
      ],
      verify: (_) => verify(() => notes.disablePush()).called(1),
    );

    test('denied push permission still saves the preference', () async {
      when(() => profiles.setAlerts('u1', true)).thenAnswer((_) async {});
      when(() => notes.enablePush('u1'))
          .thenThrow(StateError('Push permission denied'));
      final cubit = ProfileCubit(profiles, notes);
      expect(
        await cubit.saveAlerts('u1', true),
        'Preferences saved. Push was not turned on: Push permission denied',
      );
      expect(cubit.state.alertsEnabled, isTrue);
    });

    blocTest<ProfileCubit, ProfileState>(
      'simulated Plus upgrade is stored',
      setUp: () =>
          when(() => profiles.setPlus('u1', true)).thenAnswer((_) async {}),
      build: () => ProfileCubit(profiles, notes),
      act: (c) => c.setPlus('u1', true),
      expect: () => [const ProfileState(settings: ProfileSettings(plus: true))],
    );
  });
}
