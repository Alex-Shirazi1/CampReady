// In-memory backend for tests and the LOCAL_DEMO preview. Same shapes as
// Firestore; nothing leaves the device. The seeded john.doe@example.com
// account backs the demo-only sample screens.

import 'models.dart';

class LocalStore {
  LocalStore() {
    _usersByEmail['john.doe@example.com'] = _LocalAccount(
      user: const AppUser(
        uid: 'local_sample',
        email: 'john.doe@example.com',
        displayName: 'John Doe',
      ),
      passwordHash: _hash('campready123'),
    );
  }

  static String _hash(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }

  final Map<String, _LocalAccount> _usersByEmail = {};
  final Map<String, AppUser> _profiles = {};
  final Map<String, Map<String, dynamic>> userSettings = {};
  final Map<String, Map<String, SavedCampsite>> _saved = {};
  final Map<String, TripRecord> _trips = {};
  final Map<String, Map<String, Map<String, String>>> responses = {};
  final Map<String, List<AppNotification>> _notifications = {};
  // Trip-scoped notifications, one write per trip event, read by the
  // owner and by invitees (see FirestoreService.addTripNotification).
  final Map<String, List<AppNotification>> _tripNotifications = {};
  // Per-user read markers for trip notifications: a trip notification
  // is shared, so "read" cannot live on the shared record itself.
  final Map<String, Set<String>> _notificationReads = {};
  final Map<String, Set<String>> _tokens = {};
  final Set<String> _resetRequests = {};
  int _counter = 0;

  String nextId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';

  // --- auth ---

  AppUser? findUser(String email) =>
      _usersByEmail[email.trim().toLowerCase()]?.user;

  bool checkPassword(String email, String password) {
    final account = _usersByEmail[email.trim().toLowerCase()];
    return account != null && account.passwordHash == _hash(password);
  }

  AppUser createUser(String email, String password, String? displayName) {
    final normalized = email.trim().toLowerCase();
    final user = AppUser(
      uid: nextId('local'),
      email: normalized,
      displayName: displayName?.trim().isEmpty == true
          ? null
          : displayName?.trim(),
    );
    _usersByEmail[normalized] = _LocalAccount(
      user: user,
      passwordHash: _hash(password),
    );
    _profiles[user.uid] = user;
    return user;
  }

  AppUser? updateDisplayName(String uid, String displayName) {
    final profile = _profiles[uid];
    if (profile == null) return null;
    final updated = profile.copyWith(displayName: displayName);
    _profiles[uid] = updated;
    for (final entry in _usersByEmail.entries) {
      if (entry.value.user.uid == uid) {
        _usersByEmail[entry.key] = _LocalAccount(
          user: updated,
          passwordHash: entry.value.passwordHash,
        );
        break;
      }
    }
    return updated;
  }

  void recordPasswordReset(String email) {
    _resetRequests.add(email.trim().toLowerCase());
  }

  bool get passwordResetRequestedForSample =>
      _resetRequests.contains('john.doe@example.com');

  bool passwordResetRequested(String email) =>
      _resetRequests.contains(email.trim().toLowerCase());

  // --- profiles / saved campsites ---

  void saveProfile(AppUser user) => _profiles[user.uid] = user;

  AppUser? profile(String uid) => _profiles[uid];

  void saveCampsite(String uid, SavedCampsite site) {
    _saved.putIfAbsent(uid, () => {})[site.siteId] = site;
  }

  void removeCampsite(String uid, String siteId) {
    _saved[uid]?.remove(siteId);
  }

  List<SavedCampsite> savedCampsites(String uid) =>
      _saved[uid]?.values.toList() ?? [];

  bool isCampsiteSaved(String uid, String siteId) =>
      _saved[uid]?.containsKey(siteId) ?? false;

  // --- trips ---

  TripRecord putTrip(TripRecord trip) {
    // Round-trip through the model boundary so stored trips are
    // normalised (lowercased emails) even though local mode never
    // serialises to Firestore.
    final normalized = TripRecord.fromMap(trip.toMap());
    _trips[normalized.id] = normalized;
    return normalized;
  }

  TripRecord? trip(String id) => _trips[id];

  void deleteTrip(String id) => _trips.remove(id);

  List<TripRecord> tripsFor(String uid, String email) {
    final normalized = email.trim().toLowerCase();
    return _trips.values
        .where(
          (t) =>
              t.ownerUid == uid ||
              t.sharedWithEmails
                  .map((e) => e.toLowerCase())
                  .contains(normalized),
        )
        .toList();
  }

  // --- notifications / tokens ---

  AppNotification addNotification(String uid, AppNotification notification) {
    _notifications.putIfAbsent(uid, () => []).insert(0, notification);
    return notification;
  }

  List<AppNotification> notifications(String uid) =>
      List.of(_notifications[uid] ?? []);

  /// Trip notifications for one trip, newest first.
  List<AppNotification> tripNotifications(String tripId) =>
      List.of(_tripNotifications[tripId] ?? []);

  AppNotification addTripNotification(
    String tripId,
    AppNotification notification,
  ) {
    _tripNotifications.putIfAbsent(tripId, () => []).insert(0, notification);
    return notification;
  }

  bool isNotificationRead(String uid, String id) =>
      _notificationReads[uid]?.contains(id) ?? false;

  Set<String> readNotificationIds(String uid) =>
      Set.of(_notificationReads[uid] ?? {});

  void markNotificationRead(String uid, String id) {
    final list = _notifications[uid];
    final index = list?.indexWhere((n) => n.id == id) ?? -1;
    if (index >= 0) {
      list![index] = list[index].copyWith(read: true);
      return;
    }
    // Not in the user's own list: it is a shared trip notification,
    // so record the read per-user instead of mutating the shared copy.
    _notificationReads.putIfAbsent(uid, () => {}).add(id);
  }

  void saveToken(String uid, String token) {
    _tokens.putIfAbsent(uid, () => {}).add(token);
  }

  void removeToken(String uid, String token) => _tokens[uid]?.remove(token);

  Set<String> tokens(String uid) => Set.of(_tokens[uid] ?? {});
}

class _LocalAccount {
  const _LocalAccount({required this.user, required this.passwordHash});
  final AppUser user;
  final String passwordHash;
}
