import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/campsite.dart';
import '../../repositories/campsite_repository.dart';
import '../../repositories/location_repository.dart';

part 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this.campsiteRepository, this.locationRepository)
    : super(ExploreState(results: campsiteRepository.all));

  final CampsiteRepository campsiteRepository;
  final LocationRepository locationRepository;

  void search(String query) => _emitWith(query: query.trim());

  void clearSearch() => _emitWith(query: '');

  void setFilters(CampsiteFilters filters) =>
      emit(state.copyWith(filters: filters));

  void resetFilters() => emit(state.copyWith(filters: const CampsiteFilters()));

  List<Campsite> get matches =>
      campsiteRepository.all.where(state.filters.matches).toList();

  /// Reads the GPS position and sorts campsites by distance.
  Future<LocationStatus> locate() async {
    emit(state.copyWith(location: LocationStatus.locating));
    final result = await locationRepository.currentPosition();
    if (result.status != LocationStatus.granted) {
      emit(
        state.copyWith(
          location: result.status,
          distances: const {},
          results: campsiteRepository.search(state.query),
        ),
      );
      return result.status;
    }
    final distances = {
      for (final site in campsiteRepository.all)
        site.id: locationRepository.milesBetween(
          result.latitude!,
          result.longitude!,
          site.latitude,
          site.longitude,
        ),
    };
    _emitWith(
      query: '',
      location: LocationStatus.granted,
      distances: distances,
    );
    return LocationStatus.granted;
  }

  void _emitWith({
    required String query,
    LocationStatus? location,
    Map<String, double>? distances,
  }) {
    final miles = distances ?? state.distances;
    final results = [...campsiteRepository.search(query)];
    if (miles.isNotEmpty) {
      results.sort(
        (a, b) => (miles[a.id] ?? double.infinity).compareTo(
          miles[b.id] ?? double.infinity,
        ),
      );
    }
    emit(
      state.copyWith(
        query: query,
        results: results,
        location: location,
        distances: miles,
      ),
    );
  }
}
