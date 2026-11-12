import 'package:bloc_test/bloc_test.dart';
import 'package:campready/blocs/trips/trips_cubit.dart';
import 'package:campready/models/stay.dart';
import 'package:campready/repositories/campsite_repository.dart';
import 'package:campready/repositories/trip_repository.dart';
import 'package:campready/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  const owner = AppUser(uid: 'o1', email: 'owner@example.com');
  const friend = AppUser(uid: 'f1', email: 'friend@example.com');
  final redwood = campsiteCatalog.first;
  final sunset = campsiteCatalog.last;
  final stay = Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 14));
  final record = TripRepository.newTrip(
    owner: owner,
    siteId: redwood.id,
    siteName: redwood.name,
    stay: stay,
    alerts: true,
  );
  final ownedView = TripView(record: record, isOwner: true);
  final sharedView = TripView(record: record, isOwner: false);
  late MockTripRepository repo;

  setUpAll(() {
    registerFallbackValue(record);
    registerFallbackValue(owner);
  });
  setUp(() {
    repo = MockTripRepository();
    when(
      () => repo.notifyChange(
        any(),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notifyOwner: any(named: 'notifyOwner'),
      ),
    ).thenAnswer(
      (_) async => const AppNotification(id: 'n', title: 't', body: 'b'),
    );
  });

  blocTest<TripsCubit, TripsState>(
    'load emits loading then the trips',
    setUp: () =>
        when(() => repo.tripsFor(owner)).thenAnswer((_) async => [ownedView]),
    build: () => TripsCubit(repo),
    act: (c) => c.load(owner),
    expect: () => [
      const TripsState(status: TripsStatus.loading),
      TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    ],
  );

  blocTest<TripsCubit, TripsState>(
    'load failure keeps a readable error',
    setUp: () => when(() => repo.tripsFor(owner)).thenThrow(Exception('x')),
    build: () => TripsCubit(repo),
    act: (c) => c.load(owner),
    expect: () => [
      const TripsState(status: TripsStatus.loading),
      const TripsState(
        status: TripsStatus.failure,
        error: 'Could not load your trips. Check your connection.',
      ),
    ],
  );

  blocTest<TripsCubit, TripsState>(
    'book creates the trip with real dates',
    setUp: () =>
        when(() => repo.create(any()))
            .thenAnswer((i) async => i.positionalArguments.first as TripRecord),
    build: () => TripsCubit(repo),
    act: (c) => c.book(
      user: owner,
      site: redwood,
      stay: stay,
      alerts: true,
      plus: false,
    ),
    verify: (c) {
      final trip = c.state.trips.single.record;
      expect(trip.id, 'trip_o1_Redwood_Grove');
      expect(trip.siteId, 'redwood-grove');
      expect(trip.dates, 'Dec 12–14, 2026');
      expect(trip.stay, stay);
    },
  );

  blocTest<TripsCubit, TripsState>(
    'free plan cannot add a second trip',
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.book(
      user: owner,
      site: sunset,
      stay: stay,
      alerts: true,
      plus: false,
    ),
    errors: () => [isA<PlanLimitException>()],
    verify: (_) => verifyNever(() => repo.create(any())),
  );

  blocTest<TripsCubit, TripsState>(
    'a second trip at the same campsite is refused',
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.book(
      user: owner,
      site: redwood,
      stay: stay,
      alerts: true,
      plus: true,
    ),
    errors: () => [isA<StateError>()],
  );

  blocTest<TripsCubit, TripsState>(
    'changing dates saves and notifies the group',
    setUp: () => when(() => repo.update(any())).thenAnswer((_) async {}),
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.changeDates(
      ownedView,
      Stay(DateTime(2026, 12, 19), DateTime(2026, 12, 21)),
      notifyOwner: false,
    ),
    verify: (c) {
      expect(c.state.trips.single.record.dates, 'Dec 19–21, 2026');
      verify(
        () => repo.notifyChange(
          any(),
          title: 'Redwood Grove: dates changed',
          body: 'Your trip dates are now Dec 19–21, 2026.',
          notifyOwner: false,
        ),
      ).called(1);
    },
  );

  blocTest<TripsCubit, TripsState>(
    'a failed save leaves the old dates',
    setUp: () => when(() => repo.update(any())).thenThrow(Exception('offline')),
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.changeDates(
      ownedView,
      Stay(DateTime(2026, 12, 19), DateTime(2026, 12, 21)),
      notifyOwner: true,
    ),
    errors: () => [isA<Exception>()],
    expect: () => <TripsState>[],
  );

  blocTest<TripsCubit, TripsState>(
    'invitees cannot change the owner trip',
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [sharedView]),
    act: (c) => c.changeDates(sharedView, stay, notifyOwner: true),
    errors: () => [isA<StateError>()],
  );

  blocTest<TripsCubit, TripsState>(
    'sharing with your own email is refused',
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.share(ownedView, ' Owner@Example.com '),
    errors: () => [isA<StateError>()],
    verify: (_) => verifyNever(() => repo.share(any(), any())),
  );

  blocTest<TripsCubit, TripsState>(
    'share stores the invitee and writes the invitation notice',
    setUp: () {
      when(() => repo.share(any(), 'friend@example.com')).thenAnswer(
        (_) async => record.copyWith(sharedWithEmails: ['friend@example.com']),
      );
      when(() => repo.notifyShared(any(), 'friend@example.com'))
          .thenAnswer((_) async {});
    },
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.share(ownedView, 'Friend@Example.com'),
    verify: (c) {
      expect(c.state.trips.single.record.sharedWithEmails, [
        'friend@example.com',
      ]);
      verify(() => repo.notifyShared(any(), 'friend@example.com')).called(1);
    },
  );

  test('share returns a warning when only the notice fails', () async {
    when(() => repo.share(any(), any())).thenAnswer(
      (_) async => record.copyWith(sharedWithEmails: ['friend@example.com']),
    );
    when(() => repo.notifyShared(any(), any())).thenThrow(Exception('x'));
    final cubit = TripsCubit(repo)
      ..emit(TripsState(status: TripsStatus.loaded, trips: [ownedView]));
    expect(
      await cubit.share(ownedView, 'friend@example.com'),
      'Trip shared, but the invitation notice could not be saved.',
    );
  });

  blocTest<TripsCubit, TripsState>(
    'declining removes the shared trip from the list',
    setUp: () =>
        when(() => repo.respond(any(), friend, false)).thenAnswer((_) async {}),
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [sharedView]),
    act: (c) => c.respond(sharedView, friend, false),
    expect: () => [const TripsState(status: TripsStatus.loaded)],
  );

  blocTest<TripsCubit, TripsState>(
    'accepting marks the invitee as joined',
    setUp: () =>
        when(() => repo.respond(any(), friend, true)).thenAnswer((_) async {}),
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [sharedView]),
    act: (c) => c.respond(sharedView, friend, true),
    verify: (c) {
      expect(c.state.trips.single.myResponse, 'accepted');
      expect(c.state.trips.single.people, 'You joined the trip');
    },
  );

  blocTest<TripsCubit, TripsState>(
    'remove deletes only that trip',
    setUp: () => when(() => repo.delete(record.id)).thenAnswer((_) async {}),
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.remove(ownedView),
    expect: () => [const TripsState(status: TripsStatus.loaded)],
  );

  blocTest<TripsCubit, TripsState>(
    'revoke clears the invitees',
    setUp: () => when(() => repo.revoke(any())).thenAnswer(
      (_) async => record.copyWith(
        sharedWithEmails: [],
        invitation: 'Invitation revoked',
      ),
    ),
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.revoke(ownedView),
    verify: (c) => expect(c.state.trips.single.people, 'Invitation revoked'),
  );

  blocTest<TripsCubit, TripsState>(
    'offline copy keeps the dates it was saved with',
    setUp: () => when(() => repo.update(any())).thenAnswer((_) async {}),
    build: () => TripsCubit(repo),
    seed: () => TripsState(status: TripsStatus.loaded, trips: [ownedView]),
    act: (c) => c.setOfflineCopy(ownedView, saved: true),
    verify: (c) {
      expect(
        c.state.downloads.single.record.downloadedDates,
        'Dec 12–14, 2026',
      );
    },
  );

  test('owner sees each invitee answer', () {
    final view = TripView(
      record: record.copyWith(
        sharedWithEmails: ['a@example.com', 'b@example.com'],
      ),
      isOwner: true,
      responses: const [InviteResponse('a@example.com', 'accepted')],
    );
    expect(view.people, 'a@example.com: accepted\nb@example.com: pending');
  });
}
