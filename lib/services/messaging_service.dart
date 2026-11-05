// Firebase Cloud Messaging for CampReady.
//
// Configured mode: FirebaseMessaging — request permission, get the
// FCM token and save it under users/{uid}/fcmTokens, and listen for
// foreground messages. A condition change is delivered by writing a
// notification record to Firestore (see notifyConditionChange) — the
// server side that sends the FCM push for that record is a Firebase
// Cloud Function / Cloud Messaging send, to be added with the Firebase
// project; see docs/FIRST_INTEGRATIONS.md.
// Local mode: permission is granted in-app, the token is a local
// identifier saved to the local store, and condition changes are
// delivered immediately through [onMessage] and the notification
// record — no push leaves the device.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'firestore_service.dart';
import 'local_store.dart';
import 'models.dart';

class MessagingService {
  MessagingService({
    required this._store,
    required this._firestore,
    required this.useFirebase,
  });

  final LocalStore _store;
  final FirestoreService _firestore;
  final bool useFirebase;

  final _controller = StreamController<AppNotification>.broadcast();

  /// Notifications delivered while the app is open: FCM foreground
  /// messages when configured, local condition changes otherwise.
  Stream<AppNotification> get onMessage => _controller.stream;

  /// Notifications delivered in this session (local mode, and any
  /// FCM foreground message received in configured mode).
  List<AppNotification> get delivered => List.of(_delivered);
  final List<AppNotification> _delivered = [];

  String? _token;

  Future<void> initialize() async {
    if (!useFirebase) return;
    try {
      FirebaseMessaging.onMessage.listen((message) {
        final notification = AppNotification(
          id: message.messageId ?? _store.nextId('fcm'),
          title: message.notification?.title ?? 'Trip update',
          body: message.notification?.body ?? '',
          tripId: message.data['tripId'],
          site: message.data['site'],
          createdAt: DateTime.now(),
        );
        _delivered.insert(0, notification);
        if (!_controller.isClosed) _controller.add(notification);
      });
    } catch (_) {
      // Messaging must never break app start; local delivery remains.
    }
  }

  Future<bool> requestPermission() async {
    if (!useFirebase) return true;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus ==
          AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// The messaging registration for this device when configured
  /// (firebase_messaging 17: `register()` + `onRegistered` yield the
  /// Firebase Installation ID used as the direct-send target);
  /// a local identifier otherwise. Returns null only if registration
  /// fails in configured mode.
  Future<String?> getToken(String uid) async {
    if (useFirebase) {
      try {
        final registered = FirebaseMessaging.instance.onRegistered.first;
        await FirebaseMessaging.instance.register();
        _token = await registered.timeout(const Duration(seconds: 10));
        if (_token != null) await saveToken(uid, _token!);
        return _token;
      } catch (_) {
        return null;
      }
    }
    _token ??= 'local-token-$uid';
    await saveToken(uid, _token!);
    return _token;
  }

  Future<void> saveToken(String uid, String token) async {
    await _firestore.saveFcmToken(uid, token);
  }

  /// Records a condition change for a trip and delivers it: writes an
  /// AppNotification for the owner (and for every invited email whose
  /// account exists locally / in Firestore), emits it on [onMessage],
  /// and keeps it in [delivered] so the Alerts screen can show it.
  /// The FCM push itself is sent by the backend for that record once
  /// a Firebase project with Cloud Messaging is configured.
  Future<AppNotification> notifyConditionChange({
    required String ownerUid,
    required String ownerEmail,
    required String tripId,
    required String site,
    required String title,
    required String body,
    List<String> sharedWithEmails = const [],
  }) async {
    final notification = AppNotification(
      id: _store.nextId('notif'),
      title: title,
      body: body,
      tripId: tripId,
      site: site,
      createdAt: DateTime.now(),
    );
    await _firestore.addNotification(ownerUid, notification);
    for (final email in sharedWithEmails) {
      final invitee = _store.findUser(email);
      if (invitee != null && invitee.uid != ownerUid) {
        await _firestore.addNotification(invitee.uid, notification);
      }
    }
    _delivered.insert(0, notification);
    if (!_controller.isClosed) _controller.add(notification);
    return notification;
  }

  /// Notifies the invitee that they were added to a trip.
  Future<AppNotification> notifyTripShared({
    required String ownerUid,
    required String ownerEmail,
    required String inviteeEmail,
    required String tripId,
    required String site,
  }) async {
    final notification = AppNotification(
      id: _store.nextId('notif'),
      title: 'You were invited to $site',
      body: '$ownerEmail invited you to a CampReady trip.',
      tripId: tripId,
      site: site,
      createdAt: DateTime.now(),
    );
    final invitee = _store.findUser(inviteeEmail);
    if (invitee != null) {
      await _firestore.addNotification(invitee.uid, notification);
    }
    _delivered.insert(0, notification);
    if (!_controller.isClosed) _controller.add(notification);
    return notification;
  }
}
