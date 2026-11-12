import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/stay.dart';

part 'booking_state.dart';

/// The trip being planned or edited: campsite, dates and alert choice.
class BookingCubit extends Cubit<BookingState> {
  BookingCubit({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const BookingState());

  final DateTime Function() _clock;

  DateTime get today => dateOnly(_clock());

  void start(String siteId, {required bool alerts}) =>
      emit(BookingState(siteId: siteId, alerts: alerts));

  void edit({
    required String siteId,
    required String tripId,
    required Stay? stay,
    required bool alerts,
  }) => emit(
    BookingState(
      siteId: siteId,
      editingTripId: tripId,
      stay: stay,
      alerts: alerts,
    ),
  );

  /// Returns false and keeps the previous dates when [stay] is invalid.
  bool select(Stay stay) {
    final error = stay.validate(today);
    if (error != null) {
      emit(state.copyWith(error: error));
      return false;
    }
    emit(state.copyWith(stay: stay));
    return true;
  }

  void setAlerts(bool alerts) => emit(state.copyWith(alerts: alerts));

  void clear() => emit(const BookingState());
}
