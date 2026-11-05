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

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // --- profiles ---

  Future<void> saveUserProfile(AppUser user) async {
    if (useFirebase) {
      await _db.collection('users').doc(user.uid).set(user.toMap());
      return;
    }
    _store.saveProfile(user);
  }

  Future<AppUser?> getUserProfile(String uid) async {
    if (useFirebase) {
      final doc = await _db.collection('users').doc(uid).get();
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
          .set(site.toMap());
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
          .delete();
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
          .get();
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
          .get();
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
            (snap) => snap.docs
                .map((d) => SavedCampsite.fromMap(d.data()))
                .toList(),
          );
    }
    return Stream.value(_store.savedCampsites(uid));
  }

  // --- trips ---

  Future<TripRecord> createTrip(TripRecord trip) async {
    if (useFirebase) {
      await _db.collection('trips').doc(trip.id).set(trip.toMap());
      return trip;
    }
    return _store.putTrip(trip);
  }

  Future<void> updateTrip(TripRecord trip) async {
    if (useFirebase) {
      await _db.collection('trips').doc(trip.id).set(trip.toMap());
      return;
    }
    _store.putTrip(trip);
  }

  Future<TripRecord?> getTrip(String tripId) async {
    if (useFirebase) {
      final doc = await _db.collection('trips').doc(tripId).get();
      final data = doc.data();
      return data == null ? null : TripRecord.fromMap(data);
    }
    return _store.trip(tripId);
  }

  Future<void> deleteTrip(String tripId) async {
    if (useFirebase) {
      await _db.collection('trips').doc(tripId).delete();
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
          .get();
      final shared = await _db
          .collection('trips')
          .where('sharedWithEmails', arrayContains: email.toLowerCase())
          .get();
      final byId = <String, TripRecord>{};
      for (final doc in [...owned.docs, ...shared.docs]) {
        byId[doc.id] = TripRecord.fromMap(doc.data());
      }
      return byId.values.toList();
    }
    return _store.tripsFor(uid, email);
  }

  /// Adds [email] to the trip's invitee list and returns the updated
  /// trip. Callers also write an invitation notification for the
  /// invitee through MessagingService.
  Future<TripRecord> shareTrip({
    required String tripId,
    required String email,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) {
      throw StateError('Trip $tripId not found');
    }
    final normalized = email.trim().toLowerCase();
    if (trip.sharedWithEmails.map((e) => e.toLowerCase()).contains(
      normalized,
    )) {
      return trip;
    }
    final updated = trip.copyWith(
      sharedWithEmails: [...trip.sharedWithEmails, normalized],
      invitation: 'Invitation pending · $normalized',
    );
    await updateTrip(updated);
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
          .set(notification.toMap());
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
          .get();
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
          .update({'read': true});
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
          .set({'token': token});
      return;
    }
    _store.saveToken(uid, token);
  }
}
