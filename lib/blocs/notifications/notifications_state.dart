part of 'notifications_bloc.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.items = const [],
    this.latest,
    this.latestType,
    this.received = 0,
    this.error,
  });

  /// Trip updates for the signed-in account, newest first.
  final List<AppNotification> items;

  /// The last push that arrived, and how it arrived.
  final AppNotification? latest;
  final NotificationType? latestType;

  /// Counts arrivals so two equal messages still notify listeners.
  final int received;
  final String? error;

  NotificationsState copyWith({
    List<AppNotification>? items,
    AppNotification? latest,
    NotificationType? latestType,
    int? received,
    String? error,
  }) => NotificationsState(
    items: items ?? this.items,
    latest: latest ?? this.latest,
    latestType: latestType ?? this.latestType,
    received: received ?? this.received,
    error: error,
  );

  @override
  List<Object?> get props => [items, latest, latestType, received, error];
}
