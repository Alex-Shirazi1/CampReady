import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/services.dart';

class NotificationRepository {
  NotificationRepository(this._messaging, this._firestore);

  final MessagingService _messaging;
  final FirestoreService _firestore;

  /// Messages received while the app is open.
  Stream<AppNotification> get onMessage => _messaging.onMessage;

  /// Notifications the user tapped while the app was in the background.
  Stream<AppNotification> get onMessageOpenedApp =>
      _messaging.onMessageOpened.map(fromRemote);

  Future<AppNotification?> initialMessage() => _messaging.initialMessage();

  String get pushStatus => _messaging.status;

  /// In-app list for [user], newest first. When [tripIds] is given,
  /// only updates for those trips (or with no trip) are kept.
  Future<List<AppNotification>> load(
    AppUser user, {
    Set<String>? tripIds,
  }) async {
    final notes = await _firestore.notifications(user.uid, email: user.email);
    if (tripIds == null) return notes;
    return notes
        .where((n) => n.tripId == null || tripIds.contains(n.tripId))
        .toList();
  }

  Future<void> markRead(String uid, String id) =>
      _firestore.markNotificationRead(uid, id);

  /// Asks for permission and saves this device's token for [uid].
  /// Throws a [StateError] with a readable message on failure.
  Future<void> enablePush(String uid) async {
    final granted = await _messaging.requestPermission();
    if (!granted) throw StateError(_messaging.status);
    final token = await _messaging.getToken(uid);
    if (token == null) {
      throw StateError(
        'Push registration failed. Check your connection and retry.',
      );
    }
  }

  Future<void> disablePush() => _messaging.detachUser();

  static AppNotification fromRemote(RemoteMessage message) => AppNotification(
    id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
    title: message.notification?.title ?? 'Trip update',
    body: message.notification?.body ?? '',
    tripId: message.data['tripId'] as String?,
    site: message.data['site'] as String?,
    createdAt: DateTime.now(),
  );
}
