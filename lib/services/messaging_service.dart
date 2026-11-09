import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
  final _openedController = StreamController<RemoteMessage>.broadcast();

  /// Notifications delivered while the app is open: FCM foreground
  /// messages when configured, local condition changes otherwise.
  Stream<AppNotification> get onMessage => _controller.stream;

  /// FCM messages the user tapped while the app was in the
  /// background. The app routes these to the tapped trip.
  Stream<RemoteMessage> get onMessageOpened => _openedController.stream;

  /// Notifications delivered in this session (local mode, and any
  /// FCM foreground message received in configured mode).
  List<AppNotification> get delivered => List.of(_delivered);
  final List<AppNotification> _delivered = [];

  String? _token;
  String? _uid;
  String? get registeredUid => _uid;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<String>? _registration;
  String status = 'Push not enabled';
  static const emulator = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const vapidKey = String.fromEnvironment(
    'FCM_VAPID_KEY',
    // Public Web Push certificate key for campready-group2 — a public
    // client configuration value, not a secret. Override per project
    // with --dart-define=FCM_VAPID_KEY=… (see docs/FIRST_INTEGRATIONS).
    defaultValue: 'BGeSQTWeHDPAyNrhJJOFCnQ7-Bc0Kq2fqh_nWJmQ6DnfSkXo6Q3nPixmgJ2QyhjIWhWm6h_c3ePZiTHE5oEhzfE',
  );

  Future<void> initialize() async {
    if (!useFirebase || emulator) return;
    _foreground ??= FirebaseMessaging.onMessage.listen((message) {
      if (_uid == null || FirebaseAuth.instance.currentUser?.uid != _uid) {
        return;
      }
      final notification = AppNotification(
        id: message.messageId ?? _store.nextId('fcm'),
        title: message.notification?.title ?? 'Trip update',
        body: message.notification?.body ?? '',
        tripId: message.data['tripId'] as String?,
        site: message.data['site'] as String?,
        createdAt: DateTime.now(),
      );
      if (_delivered.any((n) => n.id == notification.id)) return;
      _delivered.insert(0, notification);
      if (!_controller.isClosed) _controller.add(notification);
      unawaited(
        _firestore.addNotification(_uid!, notification).catchError((
          Object error,
        ) {
          status = 'Message received; saving it failed';
          return notification;
        }),
      );
    });
    _opened ??= FirebaseMessaging.onMessageOpenedApp.listen(
      handleOpenedMessage,
    );
    // Token refresh: firebase_messaging 17 deprecated onTokenRefresh;
    // onRegistered emits the token whenever registration changes,
    // including a refresh. When a new token arrives for the signed-in
    // account, save it and remove the old one.
    _tokenRefresh ??= FirebaseMessaging.instance.onRegistered.listen((
      newToken,
    ) async {
      final uid = _uid;
      if (uid == null || newToken == _token) return;
      final old = _token;
      _token = newToken;
      try {
        await saveToken(uid, newToken);
        if (old != null) {
          await _firestore.removeFcmToken(uid, old);
        }
        status = 'Push registration saved';
      } catch (_) {
        status = 'Push registration could not be saved';
      }
    });
  }

  /// Handles a tapped background notification: records it like a
  /// foreground message and emits the raw message so the app can
  /// route to its trip. Kept separate from the listener so tests can
  /// drive it with a constructed [RemoteMessage].
  void handleOpenedMessage(RemoteMessage message) {
    final notification = AppNotification(
      id: message.messageId ?? _store.nextId('fcm-opened'),
      title: message.notification?.title ?? 'Trip update',
      body: message.notification?.body ?? '',
      tripId: message.data['tripId'] as String?,
      site: message.data['site'] as String?,
      createdAt: DateTime.now(),
    );
    if (_delivered.any((n) => n.id == notification.id)) return;
    _delivered.insert(0, notification);
    if (!_controller.isClosed) _controller.add(notification);
    if (!_openedController.isClosed) _openedController.add(message);
  }

  Future<void> restoreRegistration(String uid) async {
    if (!useFirebase || emulator || (kIsWeb && vapidKey.isEmpty)) return;
    if (!await FirebaseMessaging.instance.isSupported()) return;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await getToken(uid);
    }
  }

  Future<bool> requestPermission() async {
    if (emulator) {
      status = 'Push cannot be tested in the Firebase emulators';
      return false;
    }
    if (!useFirebase) return true;
    if (kIsWeb && vapidKey.isEmpty) {
      status = 'Web push needs the project VAPID key';
      return false;
    }
    if (!await FirebaseMessaging.instance.isSupported()) {
      status = 'Push is not supported by this browser';
      return false;
    }
    final settings = await FirebaseMessaging.instance.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    status = granted
        ? 'Permission granted; registration pending'
        : 'Push permission denied';
    return granted;
  }

  Future<String?> getToken(String uid) async {
    if (emulator) return null;
    if (useFirebase && FirebaseAuth.instance.currentUser?.uid != uid) {
      return null;
    }
    _uid = uid;
    if (!useFirebase) {
      _token = 'local-token-$uid';
      await saveToken(uid, _token!);
      status = 'Local demo only';
      return _token;
    }
    if (kIsWeb && vapidKey.isEmpty) {
      status = 'Web push needs the project VAPID key';
      return null;
    }
    await _registration?.cancel();
    final registered = Completer<String>();
    _registration = FirebaseMessaging.instance.onRegistered.listen(
      (token) async {
        if (_uid != uid) return;
        try {
          await saveToken(uid, token);
          if (_uid != uid) return;
          _token = token;
          status = 'Push registration saved';
          if (!registered.isCompleted) registered.complete(token);
        } catch (error) {
          status = 'Push registration could not be saved';
          if (!registered.isCompleted) registered.completeError(error);
        }
      },
      onError: (Object error) {
        if (!registered.isCompleted) registered.completeError(error);
      },
    );
    try {
      final result = await Future.wait([
        FirebaseMessaging.instance.register(
          vapidKey: kIsWeb ? vapidKey : null,
          serviceWorkerScriptPath: kIsWeb ? 'firebase-messaging-sw.js' : null,
        ),
        registered.future,
      ]).timeout(const Duration(seconds: 15));
      return result.last as String;
    } catch (_) {
      await _registration?.cancel();
      _registration = null;
      status = 'Push registration failed; retry';
      return null;
    }
  }

  Future<void> detachUser() async {
    final uid = _uid;
    final token = _token;
    final registration = _registration;
    _registration = null;
    _uid = null;
    _token = null;
    _delivered.clear();
    status = 'Push not enabled';
    await registration?.cancel();
    if (uid != null && token != null) {
      if (useFirebase && !emulator) {
        await FirebaseMessaging.instance.unregister();
      }
      await _firestore.removeFcmToken(uid, token);
    }
  }

  Future<void> saveToken(String uid, String token) async {
    await _firestore.saveFcmToken(uid, token);
  }

  /// Delivers a condition-change notification to the owner and to
  /// every invitee, in both modes, with one write per destination:
  ///
  /// * the owner's own copy goes to their own notifications list;
  /// * one trip-scoped copy goes to `trips/{tripId}/notifications`,
  ///   which the owner and every invitee can read.
  ///
  /// The old implementation looked each invitee up in the local
  /// in-memory store (`_store.findUser`), which is empty in Firebase
  /// mode, and then wrote into the invitee's `users/{uid}` subtree,
  /// which the rules deny. Trip-scoped delivery needs neither a uid
  /// lookup nor a cross-user write, and it reaches invitees who sign
  /// up after being shared with. [sharedWithEmails] is kept so the
  /// caller still declares the recipients; delivery itself is by trip
  /// membership, so a stale or partial list cannot silently drop an
  /// invitee who is on the trip.
  ///
  /// [notifyOwner] is the owner's own alert preference. It covers only
  /// the owner's copy: invitees still get the trip-scoped copy, and
  /// each invitee's own preference decides whether they see alerts.
  Future<AppNotification> notifyConditionChange({
    required String ownerUid,
    required String ownerEmail,
    required String tripId,
    required String site,
    required String title,
    required String body,
    List<String> sharedWithEmails = const [],
    bool notifyOwner = true,
  }) async {
    final notification = AppNotification(
      id: _store.nextId('notif'),
      title: title,
      body: body,
      tripId: tripId,
      site: site,
      createdAt: DateTime.now(),
    );
    if (notifyOwner) {
      await _firestore.addNotification(ownerUid, notification);
    }
    await _firestore.addTripNotification(tripId, notification);
    if (notifyOwner) {
      _delivered.insert(0, notification);
      if (!_controller.isClosed) _controller.add(notification);
    }
    return notification;
  }

  /// Notifies the invitee that they were added to a trip. One
  /// trip-scoped write (see [notifyConditionChange]): the invitee
  /// reads it from the trip, with no uid lookup and no cross-user
  /// write. It is addressed to [inviteeEmail], so other invitees on
  /// the same trip do not see it as their own invitation. The owner
  /// gets no copy, not even in this session's in-app stream: it is
  /// their own trip, and the notice is written to the invitee.
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
      recipientEmail: inviteeEmail.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
    await _firestore.addTripNotification(tripId, notification);
    return notification;
  }
}
