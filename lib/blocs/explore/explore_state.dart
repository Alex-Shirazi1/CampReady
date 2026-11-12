part of 'explore_cubit.dart';

class ExploreState extends Equatable {
  const ExploreState({
    this.query = '',
    this.results = const [],
    this.filters = const CampsiteFilters(),
    this.location = LocationStatus.unknown,
    this.distances = const {},
  });

  final String query;
  final List<Campsite> results;
  final CampsiteFilters filters;
  final LocationStatus location;

  /// Miles from the user's position, by campsite id.
  final Map<String, double> distances;

  bool get nearMe => distances.isNotEmpty;

  String? distanceLabel(String siteId) {
    final miles = distances[siteId];
    if (miles == null) return null;
    return miles < 10
        ? '${miles.toStringAsFixed(1)} mi away'
        : '${miles.round()} mi away';
  }

  ExploreState copyWith({
    String? query,
    List<Campsite>? results,
    CampsiteFilters? filters,
    LocationStatus? location,
    Map<String, double>? distances,
  }) => ExploreState(
    query: query ?? this.query,
    results: results ?? this.results,
    filters: filters ?? this.filters,
    location: location ?? this.location,
    distances: distances ?? this.distances,
  );

  @override
  List<Object?> get props => [query, results, filters, location, distances];
}
