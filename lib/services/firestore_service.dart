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
      _store.alertPreferences[uid] = enabled;
    }
  }

  Future<bool> alertPreference(String uid) async {
    if (useFirebase) {
      final doc = await _db.collection('users').doc(uid).get().timeout(timeout);
      return doc.data()?['alertsEnabled'] as bool? ?? true;
    }
    return _store.alertPreferences[uid] ?? true;
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
    if (useFirebase) {
      await _db
          .collection('trips')
          .doc(trip.id)
          .set(trip.toMap())
          .timeout(timeout);
      return trip;
    }
    return _store.putTrip(trip);
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

  Future<List<AppNotification>> notifications(String uid) async {
    if (useFirebase) {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get()
          .timeout(timeout);
      return snap.docs.map((d) => AppNotification.fromMap(d.data())).toList();
    }
    return _store.notifications(uid);
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    if (useFirebase) {
      return _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => AppNotification.fromMap(d.data()))
                .toList(),
          );
    }
    return Stream.value(_store.notifications(uid));
  }

  Future<void> markNotificationRead(String uid, String id) async {
    if (useFirebase) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(id)
          .update({'read': true})
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
