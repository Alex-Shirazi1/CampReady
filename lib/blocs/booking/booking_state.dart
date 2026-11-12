part of 'booking_cubit.dart';

class BookingState extends Equatable {
  const BookingState({
    this.siteId,
    this.stay,
    this.alerts = true,
    this.editingTripId,
    this.error,
  });

  final String? siteId;
  final Stay? stay;
  final bool alerts;
  final String? editingTripId;
  final String? error;

  bool get isEditing => editingTripId != null;

  BookingState copyWith({Stay? stay, bool? alerts, String? error}) =>
      BookingState(
        siteId: siteId,
        stay: stay ?? this.stay,
        alerts: alerts ?? this.alerts,
        editingTripId: editingTripId,
        error: error,
      );

  @override
  List<Object?> get props => [siteId, stay, alerts, editingTripId, error];
}
