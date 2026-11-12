part of 'notifications_bloc.dart';

sealed class NotificationsEvent {}

class NotificationsStarted extends NotificationsEvent {
  NotificationsStarted(this.user, {this.tripIds = const {}});
  final AppUser user;
  final Set<String> tripIds;
}

class NotificationsStopped extends NotificationsEvent {}

class NotificationsRefreshRequested extends NotificationsEvent {
  NotificationsRefreshRequested({this.tripIds = const {}});
  final Set<String> tripIds;
}

class NotificationsOnMessageEvent extends NotificationsEvent {
  NotificationsOnMessageEvent(this.notification);
  final AppNotification notification;
}

class NotificationsOnBackgroundMessageEvent extends NotificationsEvent {
  NotificationsOnBackgroundMessageEvent(this.notification);
  final AppNotification notification;
}

class NotificationsOnMessageOpenedAppEvent extends NotificationsEvent {
  NotificationsOnMessageOpenedAppEvent(this.notification);
  final AppNotification notification;
}
