import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/campsite.dart';
import '../../models/stay.dart';
import '../../repositories/trip_repository.dart';
import '../../services/services.dart';

part 'trips_state.dart';

/// Thrown when a free account tries to plan a second trip.
class PlanLimitException implements Exception {}

class TripsCubit extends Cubit<TripsState> {
  TripsCubit(this.tripRepository) : super(const TripsState());

  final TripRepository tripRepository;
  int _loadVersion = 0;

  Future<void> load(AppUser user) async {
    final version = ++_loadVersion;
    emit(state.copyWith(status: TripsStatus.loading));
    try {
      final trips = await tripRepository.tripsFor(user);
      if (version != _loadVersion) return;
      emit(TripsState(status: TripsStatus.loaded, trips: trips));
    } catch (_) {
      if (version != _loadVersion) return;
      emit(
        state.copyWith(
          status: TripsStatus.failure,
          error: 'Could not load your trips. Check your connection.',
        ),
      );
    }
  }

  void clear() {
    _loadVersion++;
    emit(const TripsState());
  }

  /// Creates a simulated booking request for [site].
  Future<TripView> book({
    required AppUser user,
    required Campsite site,
    required Stay stay,
    required bool alerts,
    required bool plus,
  }) async {
    final existing = state.ownedFor(site.name);
    if (existing != null) {
      throw StateError('You already have a trip here. Edit its dates instead.');
    }
    if (!plus && state.ownedCount >= 1) throw PlanLimitException();
    final created = await tripRepository.create(
      TripRepository.newTrip(
        owner: user,
        siteId: site.id,
        siteName: site.name,
        stay: stay,
        alerts: alerts,
      ),
    );
    final view = TripView(record: created, isOwner: true);
    _put(view);
    return view;
  }

  /// Saves new dates and tells the group. Returns a warning when the
  /// trip saved but its notification did not.
  Future<String?> changeDates(
    TripView trip,
    Stay stay, {
    required bool notifyOwner,
  }) async {
    final updated = _owned(trip).copyWith(stay: stay);
    await tripRepository.update(updated);
    _put(trip.copyWith(record: updated));
    return _notify(
      updated,
      '${updated.site}: dates changed',
      'Your trip dates are now ${stay.label}.',
      notifyOwner,
    );
  }

  /// Simulated host response, shown only in demo builds.
  Future<String?> setStatus(
    TripView trip,
    String status, {
    required bool notifyOwner,
  }) async {
    final updated = _owned(trip).copyWith(status: status);
    await tripRepository.update(updated);
    _put(trip.copyWith(record: updated));
    return _notify(
      updated,
      '${updated.site}: booking $status',
      'Your trip request is now $status.',
      notifyOwner,
    );
  }

  Future<void> remove(TripView trip) async {
    await tripRepository.delete(_owned(trip).id);
    emit(state.copyWith(trips: [...state.trips]..remove(state.byId(trip.id))));
  }

  Future<String?> share(TripView trip, String email) async {
    final record = _owned(trip);
    final invitee = email.trim().toLowerCase();
    if (invitee == record.ownerEmail.toLowerCase()) {
      throw StateError('This is already your trip. Invite another person.');
    }
    final updated = await tripRepository.share(record, invitee);
    _put(trip.copyWith(record: updated));
    try {
      await tripRepository.notifyShared(updated, invitee);
      return null;
    } catch (_) {
      return 'Trip shared, but the invitation notice could not be saved.';
    }
  }

  Future<void> revoke(TripView trip) async {
    final updated = await tripRepository.revoke(_owned(trip));
    _put(TripView(record: updated, isOwner: true, responses: const []));
  }

  Future<void> respond(TripView trip, AppUser user, bool accept) async {
    if (trip.isOwner) {
      throw StateError('Sign in as the invited person to respond.');
    }
    await tripRepository.respond(trip.record, user, accept);
    if (accept) {
      _put(
        TripView(record: trip.record, isOwner: false, myResponse: 'accepted'),
      );
    } else {
      emit(
        state.copyWith(trips: [...state.trips]..remove(state.byId(trip.id))),
      );
    }
  }

  Future<void> setOfflineCopy(TripView trip, {required bool saved}) async {
    final updated = _owned(trip)
        .copyWith(downloadedDates: saved ? trip.record.dates : '');
    await tripRepository.update(updated);
    _put(trip.copyWith(record: updated));
  }

  TripRecord _owned(TripView trip) {
    if (!trip.isOwner) {
      throw StateError(
        'Shared trips are view-only. Ask the owner to change this trip.',
      );
    }
    return state.byId(trip.id)?.record ?? trip.record;
  }

  void _put(TripView view) {
    final trips = [...state.trips];
    final index = trips.indexWhere((t) => t.id == view.id);
    if (index >= 0) {
      trips[index] = view;
    } else {
      trips.add(view);
    }
    emit(state.copyWith(status: TripsStatus.loaded, trips: trips));
  }

  Future<String?> _notify(
    TripRecord trip,
    String title,
    String body,
    bool notifyOwner,
  ) async {
    try {
      await tripRepository.notifyChange(
        trip,
        title: title,
        body: body,
        notifyOwner: notifyOwner,
      );
      return null;
    } catch (_) {
      return 'Trip saved, but its update notice could not be sent.';
    }
  }
}
