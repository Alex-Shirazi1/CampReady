// Firestore data for CampReady.
//
// Configured mode: Cloud Firestore, collections
//   users/{uid}                        profile (AppUser)
//   users/{uid}/savedCampsites/{site}  saved campsites
//   users/{uid}/notifications/{id}     notification records
//   users/{uid}/fcmTokens/{token}      FCM installation tokens
//   trips/{tripId}                     trips; ownerUid owns the trip,
//                                      sharedWithEmails lists invitees,
//                                      so an invited user can read it.
// Local mode: the same API backed by LocalStore. Trips are visible to
// the owner and to any email listed in sharedWithEmails, in both modes.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'local_store.dart';
import 'models.dart';

class FirestoreService {
  FirestoreService({required this._store, required this.useFirebase});

  final LocalStore _store;
  final bool useFirebase;
  static const timeout = Duration(seconds: 15);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // --- profiles ---

  Future<void> saveUserProfile(AppUser user) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(timeout);
      return;
    }
    _store.saveProfile(user);
  }

  Future<void> saveAlertPreference(String uid, bool enabled) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .set({'alertsEnabled': enabled}, SetOptions(merge: true))
          .timeout(timeout);
    } else {
      _store.userSettings.putIfAbsent(uid, () => {})['alertsEnabled'] = enabled;
    }
  }

  Future<bool> alertPreference(String uid) async {
    if (useFirebase) {
      final doc = await _db.collection('users').doc(uid).get().timeout(timeout);
      return doc.data()?['alertsEnabled'] as bool? ?? true;
    }
    return _store.userSettings[uid]?['alertsEnabled'] as bool? ?? true;
  }

  /// Fields on users/{uid}: alertsEnabled, plan, photo.
  Future<Map<String, dynamic>> userSettings(String uid) async {
    if (useFirebase) {
      final doc = await _db.collection('users').doc(uid).get().timeout(timeout);
      return doc.data() ?? {};
    }
    return Map.of(_store.userSettings[uid] ?? {});
  }

  Future<void> updateUserSettings(String uid, Map<String, dynamic> data) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true))
          .timeout(timeout);
      return;
    }
    _store.userSettings.putIfAbsent(uid, () => {}).addAll(data);
  }

  Future<AppUser?> getUserProfile(String uid) async {
    if (useFirebase) {
      final doc = await _db.collection('users').doc(uid).get().timeout(timeout);
      final data = doc.data();
      return data == null ? null : AppUser.fromMap(data);
    }
    return _store.profile(uid);
  }

  Stream<AppUser?> watchUserProfile(String uid) {
    if (useFirebase) {
      return _db.collection('users').doc(uid).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : AppUser.fromMap(data);
      });
    }
    return Stream.value(_store.profile(uid));
  }

  // --- saved campsites ---

  Future<void> saveCampsite(String uid, SavedCampsite site) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('savedCampsites')
          .doc(site.siteId)
          .set(site.toMap())
          .timeout(timeout);
      return;
    }
    _store.saveCampsite(uid, site);
  }

  Future<void> removeCampsite(String uid, String siteId) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('savedCampsites')
          .doc(siteId)
          .delete()
          .timeout(timeout);
      return;
    }
    _store.removeCampsite(uid, siteId);
  }

  Future<List<SavedCampsite>> savedCampsites(String uid) async {
    if (useFirebase) {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('savedCampsites')
          .get()
          .timeout(timeout);
      return snap.docs.map((d) => SavedCampsite.fromMap(d.data())).toList();
    }
    return _store.savedCampsites(uid);
  }

  Future<bool> isCampsiteSaved(String uid, String siteId) async {
    if (useFirebase) {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('savedCampsites')
          .doc(siteId)
          .get()
          .timeout(timeout);
      return doc.exists;
    }
    return _store.isCampsiteSaved(uid, siteId);
  }

  Stream<List<SavedCampsite>> watchSavedCampsites(String uid) {
    if (useFirebase) {
      return _db
          .collection('users')
          .doc(uid)
          .collection('savedCampsites')
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => SavedCampsite.fromMap(d.data())).toList(),
          );
    }
    return Stream.value(_store.savedCampsites(uid));
  }

  // --- trips ---

  Future<TripRecord> createTrip(TripRecord trip) async {
    // Create-only: a second-device / reloaded create must not silently
    // overwrite an existing trip and wipe its shares. set() on an
    // existing doc is checked by the UPDATE rule, not the create rule,
    // so this write carries a new server-timestamp createdAt and the
    // rules keep createdAt immutable: a second create is denied, and
    // the write itself is the check.
    // Do NOT read the doc first to test for existence: the trip read
    // rule dereferences resource.data, which is null for a doc that
    // does not exist yet, so a pre-flight get is denied (403) for every
    // brand-new trip and booking can never succeed. If the write is
    // denied, only then read the doc — a doc that exists is readable
    // by its owner, so a successful read there means "already exists".
    if (useFirebase) {
      try {
        await _db
            .collection('trips')
            .doc(trip.id)
            .set({...trip.toMap(), 'createdAt': FieldValue.serverTimestamp()})
            .timeout(timeout);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          final exists = await _docExists(trip.id);
          if (exists) {
            throw StateError(
              'This trip already exists. Refresh to load the saved plan instead of creating a new one.',
            );
          }
        }
        rethrow;
      }
      return TripRecord.fromMap(trip.toMap());
    }
    if (_store.trip(trip.id) != null) {
      throw StateError(
        'This trip already exists. Refresh to load the saved plan instead of creating a new one.',
      );
    }
    return _store.putTrip(trip);
  }

  /// True when the trip doc exists and is readable by the signed-in
  /// account. False when it does not exist or cannot be read.
  Future<bool> _docExists(String tripId) async {
    try {
      final doc = await _db
          .collection('trips')
          .doc(tripId)
          .get()
          .timeout(timeout);
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateTrip(TripRecord trip) async {
    if (useFirebase) {
      final data = trip.toMap()
        ..remove('sharedWithEmails')
        ..remove('invitation');
      await _db.collection('trips').doc(trip.id).update(data).timeout(timeout);
      return;
    }
    final current = _store.trip(trip.id);
    if (current == null) throw StateError('This trip was removed.');
    _store.putTrip(
      trip.copyWith(
        sharedWithEmails: current.sharedWithEmails,
        invitation: current.invitation,
      ),
    );
  }

  Future<TripRecord?> getTrip(String tripId) async {
    if (useFirebase) {
      final doc = await _db
          .collection('trips')
          .doc(tripId)
          .get()
          .timeout(timeout);
      final data = doc.data();
      return data == null ? null : TripRecord.fromMap(data);
    }
    return _store.trip(tripId);
  }

  Future<void> deleteTrip(String tripId) async {
    if (useFirebase) {
      await _db.collection('trips').doc(tripId).delete().timeout(timeout);
      return;
    }
    _store.deleteTrip(tripId);
  }

  /// Trips the user owns plus trips shared with their email.
  Future<List<TripRecord>> tripsForUser(String uid, String email) async {
    if (useFirebase) {
      final owned = await _db
          .collection('trips')
          .where('ownerUid', isEqualTo: uid)
          .get()
          .timeout(timeout);
      final shared = await _db
          .collection('trips')
          .where('sharedWithEmails', arrayContains: email.toLowerCase())
          .get()
          .timeout(timeout);
      final byId = <String, TripRecord>{};
      for (final doc in [...owned.docs, ...shared.docs]) {
        byId[doc.id] = TripRecord.fromMap(doc.data());
      }
      return byId.values.toList();
    }
    return _store.tripsFor(uid, email);
  }

  Future<TripRecord> shareTrip({
    required String tripId,
    required String email,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) {
      throw StateError('Trip $tripId not found');
    }
    final normalized = email.trim().toLowerCase();
    final alreadyShared = trip.sharedWithEmails.contains(normalized);
    if (useFirebase) {
      final responses = await _db
          .collection('trips')
          .doc(tripId)
          .collection('responses')
          .where('email', isEqualTo: normalized)
          .get()
          .timeout(timeout);
      if (alreadyShared &&
          !responses.docs.any((r) => r.data()['status'] == 'declined')) {
        return trip;
      }
      for (final response in responses.docs) {
        await response.reference.delete().timeout(timeout);
      }
    } else {
      final responses = _store.responses[tripId]?.values ?? [];
      if (alreadyShared &&
          !responses.any(
            (r) => r['email'] == normalized && r['status'] == 'declined',
          )) {
        return trip;
      }
      _store.responses[tripId]?.removeWhere(
        (uid, response) => response['email'] == normalized,
      );
    }
    final updated = trip.copyWith(
      sharedWithEmails: {...trip.sharedWithEmails, normalized}.toList(),
      invitation: 'Invitation pending · $normalized',
    );
    if (useFirebase) {
      await _db
          .collection('trips')
          .doc(tripId)
          .update({
            'sharedWithEmails': FieldValue.arrayUnion([normalized]),
            'invitation': updated.invitation,
          })
          .timeout(timeout);
    } else {
      _store.putTrip(updated);
    }
    return updated;
  }

  Future<void> respondToInvitation(
    TripRecord trip,
    AppUser user,
    String status,
  ) async {
    if (!['accepted', 'declined'].contains(status) ||
        !trip.sharedWithEmails.contains(user.email.toLowerCase())) {
      throw StateError('This invitation is unavailable for this account.');
    }
    final data = {'email': user.email.toLowerCase(), 'status': status};
    if (useFirebase) {
      await _db
          .collection('trips')
          .doc(trip.id)
          .collection('responses')
          .doc(user.uid)
          .set(data)
          .timeout(timeout);
    } else {
      final current = _store.trip(trip.id);
      if (current == null ||
          !current.sharedWithEmails.contains(user.email.toLowerCase())) {
        throw StateError('This invitation was revoked or removed.');
      }
      _store.responses.putIfAbsent(trip.id, () => {})[user.uid] = data;
    }
  }

  Future<Map<String, String>?> invitationResponse(
    String tripId,
    String uid,
  ) async {
    if (useFirebase) {
      final snap = await _db
          .collection('trips')
          .doc(tripId)
          .collection('responses')
          .doc(uid)
          .get()
          .timeout(timeout);
      return snap.data()?.map((key, value) => MapEntry(key, value as String));
    }
    return _store.responses[tripId]?[uid];
  }

  Future<List<Map<String, String>>> invitationResponses(String tripId) async {
    if (useFirebase) {
      final snap = await _db
          .collection('trips')
          .doc(tripId)
          .collection('responses')
          .get()
          .timeout(timeout);
      return snap.docs
          .map((d) => d.data().map((k, v) => MapEntry(k, v as String)))
          .toList();
    }
    return _store.responses[tripId]?.values.toList() ?? [];
  }

  Future<TripRecord> revokeInvitations(TripRecord trip) async {
    final updated = trip.copyWith(
      sharedWithEmails: [],
      invitation: 'Invitation revoked',
    );
    if (useFirebase) {
      await _db
          .collection('trips')
          .doc(trip.id)
          .update({'sharedWithEmails': [], 'invitation': updated.invitation})
          .timeout(timeout);
    } else {
      _store.putTrip(updated);
    }
    return updated;
  }

  // --- notifications ---
  //
  // Delivery model (fixed in this revision): a trip event is written
  // ONCE to `trips/{tripId}/notifications/{id}`. The owner and every
  // invitee can read that subcollection, so delivery needs no
  // per-invitee uid lookup and no cross-user write into another
  // account's `users/{uid}` subtree (which the users rule denies).
  // The owner's own copy still goes to their own list, and FCM
  // foreground saves also go there. [notifications] merges both
  // sources for the signed-in account, newest first, de-duplicated
  // by id. A trip notification is included for invitees only — the
  // owner already has their own copy, so including it again would
  // double-count (and would show the owner an "invited" notice about
  // their own trip).

  Future<AppNotification> addNotification(
    String uid,
    AppNotification notification,
  ) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap())
          .timeout(timeout);
      return notification;
    }
    return _store.addNotification(uid, notification);
  }

  /// Writes one trip notification, readable by the trip owner and by
  /// everyone in the trip's `sharedWithEmails`. The caller must have
  /// persisted the trip first; the rules deny the write when the trip
  /// does not exist or the writer is not its owner.
  Future<AppNotification> addTripNotification(
    String tripId,
    AppNotification notification,
  ) async {
    if (useFirebase) {
      await _db
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap())
          .timeout(timeout);
      return notification;
    }
    return _store.addTripNotification(tripId, notification);
  }

  Future<List<AppNotification>> notifications(
    String uid, {
    String? email,
  }) async {
    final readIds = await _readMarkerIds(uid);
    final own = (await _ownNotifications(uid))
        .map((n) => readIds.contains(n.id) ? n.copyWith(read: true) : n)
        .toList();
    final resolvedEmail = email ?? await _emailFor(uid);
    if (resolvedEmail == null) return _sorted(own);
    final me = resolvedEmail.trim().toLowerCase();
    final visible = await tripsForUser(uid, resolvedEmail);
    final merged = <String, AppNotification>{};
    for (final note in own) {
      merged[note.id] = note;
    }
    for (final trip in visible) {
      // The owner's own copy already covers their trips; trip
      // notifications are the invitees' delivery channel.
      if (trip.ownerUid == uid) continue;
      // A denied or missing trip-notifications read (e.g. stale
      // rules without the subcollection) must not fail the whole
      // load: the trip itself is still visible, only its
      // notifications are missing.
      try {
        for (final note in await _tripNotifications(trip.id)) {
          if (merged.containsKey(note.id)) continue;
          // An invitation notice is addressed to one invitee; others on
          // the same trip must not see it as their own invitation.
          final recipient = note.recipientEmail;
          if (recipient != null && recipient != me) continue;
          merged[note.id] = readIds.contains(note.id)
              ? note.copyWith(read: true)
              : note;
        }
      } catch (_) {
        continue;
      }
    }
    return _sorted(merged.values.toList());
  }

  Future<List<AppNotification>> _ownNotifications(String uid) async {
    if (useFirebase) {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get()
          .timeout(timeout);
      return _parseNotifications(snap.docs.map((d) => d.data()));
    }
    return _store.notifications(uid);
  }

  Future<List<AppNotification>> _tripNotifications(String tripId) async {
    if (useFirebase) {
      final snap = await _db
          .collection('trips')
          .doc(tripId)
          .collection('notifications')
          .get()
          .timeout(timeout);
      return _parseNotifications(snap.docs.map((d) => d.data()));
    }
    return _store.tripNotifications(tripId);
  }

  /// Ids the user has marked read (per-user markers — see
  /// [markNotificationRead]). Applied to both the own list and to
  /// shared trip notifications when merging.
  Future<Set<String>> _readMarkerIds(String uid) async {
    if (useFirebase) {
      try {
        final snap = await _db
            .collection('users')
            .doc(uid)
            .collection('notificationReads')
            .get()
            .timeout(timeout);
        return {
          for (final doc in snap.docs)
            if (doc.data()['read'] as bool? ?? false) doc.id,
        };
      } catch (_) {
        return {};
      }
    }
    return _store.readNotificationIds(uid);
  }

  /// Resolves the email for [uid] so visible trips can be found.
  /// Returns null when it cannot be resolved (for example, reading
  /// another account's profile in Firebase mode is denied by the
  /// users rule); callers then return the user's own list only.
  Future<String?> _emailFor(String uid) async {
    if (useFirebase) {
      try {
        final profile = await getUserProfile(uid);
        if (profile != null && profile.email.isNotEmpty) {
          return profile.email;
        }
      } catch (_) {
        // Another account's profile: not readable, and not needed for
        // the signed-in account's own list.
      }
      return null;
    }
    return _store.profile(uid)?.email;
  }

  /// Parses notification docs one by one so a single malformed doc
  /// cannot fail the whole list read.
  List<AppNotification> _parseNotifications(
    Iterable<Map<String, dynamic>> docs,
  ) {
    final out = <AppNotification>[];
    for (final data in docs) {
      try {
        out.add(AppNotification.fromMap(data));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  List<AppNotification> _sorted(List<AppNotification> notes) {
    notes.sort(
      (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    );
    return notes;
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    // Live snapshots cover the user's own list only. Trip
    // notifications arrive on the next loadAccount refresh; the UI
    // loads notifications that way (DemoState.loadAccount).
    if (useFirebase) {
      return _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .snapshots()
          .map(
            (snap) =>
                _sorted(_parseNotifications(snap.docs.map((d) => d.data()))),
          );
    }
    return Stream.value(_store.notifications(uid));
  }

  Future<void> markNotificationRead(String uid, String id) async {
    if (useFirebase) {
      // set(merge) instead of update: it must not throw when the doc
      // does not exist in the user's own list (a shared trip
      // notification lives under the trip, not here). The read marker
      // is per-user, so marking one invitee's copy read does not mark
      // it read for everyone else.
      await _db
          .collection('users')
          .doc(uid)
          .collection('notificationReads')
          .doc(id)
          .set({'read': true}, SetOptions(merge: true))
          .timeout(timeout);
      return;
    }
    _store.markNotificationRead(uid, id);
  }

  // --- FCM tokens ---

  Future<void> saveFcmToken(String uid, String token) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .set({'token': token})
          .timeout(timeout);
      return;
    }
    _store.saveToken(uid, token);
  }

  Future<void> removeFcmToken(String uid, String token) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .delete()
          .timeout(timeout);
    } else {
      _store.removeToken(uid, token);
    }
  }
}
