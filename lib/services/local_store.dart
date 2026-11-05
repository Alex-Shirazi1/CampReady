// In-memory backend used when no Firebase project is configured.
// Same collections and shapes as the Firestore implementation, so
// switching backends changes storage, not behaviour. Nothing here
// leaves the device and nothing is synced.
//
// The one seeded account is the sample account from the submitted
// Figma design (john.doe@example.com / campready123, display name
// "John Doe"). It exists only so the Figma "signed-in" sample screens
// can be exercised in local mode; it is not a real account and no
// real sign-in goes through it. Passwords are stored only as a
// simple non-reversible hash, local mode only.

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
  final Map<String, Map<String, SavedCampsite>> _saved = {};
  final Map<String, TripRecord> _trips = {};
  final Map<String, List<AppNotification>> _notifications = {};
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
    _trips[trip.id] = trip;
    return trip;
  }

  TripRecord? trip(String id) => _trips[id];

  void deleteTrip(String id) => _trips.remove(id);

  List<TripRecord> tripsFor(String uid, String email) {
    final normalized = email.trim().toLowerCase();
    return _trips.values
        .where(
          (t) =>
              t.ownerUid == uid ||
              t.sharedWithEmails.map((e) => e.toLowerCase()).contains(
                normalized,
              ),
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

  void markNotificationRead(String uid, String id) {
    final list = _notifications[uid];
    if (list == null) return;
    final index = list.indexWhere((n) => n.id == id);
    if (index >= 0) list[index] = list[index].copyWith(read: true);
  }

  void saveToken(String uid, String token) {
    _tokens.putIfAbsent(uid, () => {}).add(token);
  }

  Set<String> tokens(String uid) => Set.of(_tokens[uid] ?? {});
}

class _LocalAccount {
  const _LocalAccount({required this.user, required this.passwordHash});
  final AppUser user;
  final String passwordHash;
}
