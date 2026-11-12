import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/notification_repository.dart';
import '../../services/services.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

enum NotificationType { onMessage, onBackgroundMessage, onMessageOpenedApp }

/// Registers the FCM listeners and keeps the in-app Alerts list.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this.notificationRepository)
    : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsStopped>(_onStopped);
    on<NotificationsRefreshRequested>(_onRefresh);
    on<NotificationsOnMessageEvent>(
      (event, emit) =>
          _received(event.notification, NotificationType.onMessage, emit),
    );
    on<NotificationsOnMessageOpenedAppEvent>(
      (event, emit) => _received(
        event.notification,
        NotificationType.onMessageOpenedApp,
        emit,
      ),
    );
    on<NotificationsOnBackgroundMessageEvent>(
      (event, emit) => _received(
        event.notification,
        NotificationType.onBackgroundMessage,
        emit,
      ),
    );
  }

  final NotificationRepository notificationRepository;
  StreamSubscription<AppNotification>? messageSubscription;
  StreamSubscription<AppNotification>? messageOpenedAppSubscription;
  AppUser? _user;

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    _user = event.user;
    messageSubscription ??= notificationRepository.onMessage.listen(
      (note) => add(NotificationsOnMessageEvent(note)),
    );
    messageOpenedAppSubscription ??= notificationRepository.onMessageOpenedApp
        .listen((note) => add(NotificationsOnMessageOpenedAppEvent(note)));
    await _load(event.tripIds, emit);
    try {
      final initial = await notificationRepository.initialMessage();
      if (initial != null) add(NotificationsOnBackgroundMessageEvent(initial));
    } catch (_) {}
  }

  void _onStopped(
    NotificationsStopped event,
    Emitter<NotificationsState> emit,
  ) {
    _user = null;
    emit(const NotificationsState());
  }

  Future<void> _onRefresh(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) => _load(event.tripIds, emit);

  Future<void> _load(
    Set<String>? tripIds,
    Emitter<NotificationsState> emit,
  ) async {
    final user = _user;
    if (user == null) return;
    try {
      final items = await notificationRepository.load(user, tripIds: tripIds);
      if (_user?.uid != user.uid) return;
      emit(state.copyWith(items: items, error: null));
    } catch (_) {
      emit(state.copyWith(error: 'Could not load trip updates.'));
    }
  }

  void _received(
    AppNotification note,
    NotificationType type,
    Emitter<NotificationsState> emit,
  ) {
    if (_user == null) return;
    final items = [note, ...state.items.where((n) => n.id != note.id)];
    emit(
      state.copyWith(
        items: items,
        latest: note,
        latestType: type,
        received: state.received + 1,
      ),
    );
  }

  @override
  Future<void> close() {
    messageSubscription?.cancel();
    messageOpenedAppSubscription?.cancel();
    return super.close();
  }
}
