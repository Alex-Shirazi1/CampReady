part of 'trips_cubit.dart';

enum TripsStatus { initial, loading, loaded, failure }

class TripsState extends Equatable {
  const TripsState({
    this.status = TripsStatus.initial,
    this.trips = const [],
    this.error,
  });

  final TripsStatus status;
  final List<TripView> trips;
  final String? error;

  bool get isLoaded => status == TripsStatus.loaded;

  TripView? byId(String? id) {
    for (final trip in trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  /// The signed-in user's own trip at [siteName], if any.
  TripView? ownedFor(String siteName) {
    for (final trip in trips) {
      if (trip.isOwner && trip.record.site == siteName) return trip;
    }
    return null;
  }

  int get ownedCount => trips.where((t) => t.isOwner).length;

  Iterable<TripView> get downloads =>
      trips.where((t) => t.record.downloadedDates.isNotEmpty);

  TripsState copyWith({
    TripsStatus? status,
    List<TripView>? trips,
    String? error,
  }) => TripsState(
    status: status ?? this.status,
    trips: trips ?? this.trips,
    error: error,
  );

  @override
  List<Object?> get props => [status, trips, error];
}
