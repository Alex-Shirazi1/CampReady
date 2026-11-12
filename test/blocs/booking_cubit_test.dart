import 'package:bloc_test/bloc_test.dart';
import 'package:campready/blocs/booking/booking_cubit.dart';
import 'package:campready/models/stay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 11, 15);
  BookingCubit build() => BookingCubit(clock: () => today);

  blocTest<BookingCubit, BookingState>(
    'start sets the campsite and alert choice',
    build: build,
    act: (c) => c.start('redwood-grove', alerts: false),
    expect: () => [const BookingState(siteId: 'redwood-grove', alerts: false)],
  );

  blocTest<BookingCubit, BookingState>(
    'accepts an upcoming two-night stay',
    build: build,
    seed: () => const BookingState(siteId: 'redwood-grove'),
    act: (c) => c.select(Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 14))),
    expect: () => [
      BookingState(
        siteId: 'redwood-grove',
        stay: Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 14)),
      ),
    ],
  );

  blocTest<BookingCubit, BookingState>(
    'arrival today is allowed',
    build: build,
    act: (c) => c.select(Stay(DateTime(2026, 11, 11), DateTime(2026, 11, 12))),
    expect: () => [
      BookingState(stay: Stay(DateTime(2026, 11, 11), DateTime(2026, 11, 12))),
    ],
  );

  blocTest<BookingCubit, BookingState>(
    'rejects past dates and keeps the earlier choice',
    build: build,
    seed: () => BookingState(
      stay: Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 14)),
    ),
    act: (c) => c.select(Stay(DateTime(2026, 11, 1), DateTime(2026, 11, 3))),
    expect: () => [
      BookingState(
        stay: Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 14)),
        error: 'Choose upcoming dates. Arrival can’t be in the past.',
      ),
    ],
  );

  blocTest<BookingCubit, BookingState>(
    'rejects checkout on or before arrival',
    build: build,
    act: (c) => c
      ..select(Stay(DateTime(2026, 12, 14), DateTime(2026, 12, 12)))
      ..select(Stay(DateTime(2026, 12, 14), DateTime(2026, 12, 14))),
    expect: () => [
      const BookingState(
        error: 'Checkout must be at least one night after arrival.',
      ),
    ],
  );

  blocTest<BookingCubit, BookingState>(
    'rejects stays longer than 14 nights',
    build: build,
    act: (c) => c.select(Stay(DateTime(2026, 12, 1), DateTime(2026, 12, 16))),
    expect: () => [const BookingState(error: 'Trips can be up to 14 nights.')],
  );

  blocTest<BookingCubit, BookingState>(
    'edit keeps the trip being changed',
    build: build,
    act: (c) =>
        c.edit(siteId: 'redwood-grove', tripId: 't1', stay: null, alerts: true),
    verify: (c) => expect(c.state.isEditing, isTrue),
  );

  test('stay labels across months and years', () {
    expect(
      Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 14)).label,
      'Dec 12–14, 2026',
    );
    expect(
      Stay(DateTime(2026, 11, 28), DateTime(2026, 12, 1)).label,
      'Nov 28–Dec 1, 2026',
    );
    expect(
      Stay(DateTime(2026, 12, 30), DateTime(2027, 1, 2)).label,
      'Dec 30, 2026–Jan 2, 2027',
    );
    expect(
      Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 13)).nightsLabel,
      '1 night',
    );
  });

  test('nights are counted across daylight saving changes', () {
    expect(Stay(DateTime(2026, 10, 31), DateTime(2026, 11, 2)).nights, 2);
    expect(Stay(DateTime(2027, 3, 13), DateTime(2027, 3, 15)).nights, 2);
  });

  test('stay survives a map round-trip', () {
    final stay = Stay(DateTime(2026, 12, 12), DateTime(2026, 12, 14));
    expect(Stay.fromMap(stay.toMap()), stay);
    expect(Stay.fromMap(const {'dates': 'Oct 23–25'}), isNull);
  });
}
