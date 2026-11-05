// Plain data models for the First Integrations services layer.
// These are backend-neutral: the same objects are produced by the
// Firestore implementation and by the local in-memory fallback, so
// the UI never branches on which backend is active.

/// A signed-in account. [uid] is the Firebase UID when configured,
/// or a `local_…` id in local mode.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  final String uid;
  final String email;
  final String? displayName;

  AppUser copyWith({String? displayName}) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String? ?? '',
    email: map['email'] as String? ?? '',
    displayName: map['displayName'] as String?,
  );
}

/// A campsite the user saved. Stored at
/// `users/{uid}/savedCampsites/{siteId}` in Firestore.
class SavedCampsite {
  const SavedCampsite({
    required this.siteId,
    required this.name,
    this.pricePerNight,
  });

  final String siteId;
  final String name;
  final String? pricePerNight;

  Map<String, dynamic> toMap() => {
    'siteId': siteId,
    'name': name,
    'pricePerNight': pricePerNight,
  };

  factory SavedCampsite.fromMap(Map<String, dynamic> map) => SavedCampsite(
    siteId: map['siteId'] as String? ?? '',
    name: map['name'] as String? ?? '',
    pricePerNight: map['pricePerNight'] as String?,
  );
}

/// A trip plan. Stored in the top-level `trips` collection in
/// Firestore so an invited user can read it: [ownerUid] owns it and
/// [sharedWithEmails] lists invitees by email.
class TripRecord {
  const TripRecord({
    required this.id,
    required this.ownerUid,
    required this.ownerEmail,
    required this.site,
    required this.dates,
    this.status = 'Request pending',
    this.alertsEnabled = true,
    this.downloadedDates = '',
    this.sharedWithEmails = const [],
    this.invitation = 'No invitations yet',
  });

  final String id;
  final String ownerUid;
  final String ownerEmail;
  final String site;
  final String dates;
  final String status;
  final bool alertsEnabled;
  final String downloadedDates;
  final List<String> sharedWithEmails;
  final String invitation;

  TripRecord copyWith({
    String? dates,
    String? status,
    bool? alertsEnabled,
    String? downloadedDates,
    List<String>? sharedWithEmails,
    String? invitation,
  }) => TripRecord(
    id: id,
    ownerUid: ownerUid,
    ownerEmail: ownerEmail,
    site: site,
    dates: dates ?? this.dates,
    status: status ?? this.status,
    alertsEnabled: alertsEnabled ?? this.alertsEnabled,
    downloadedDates: downloadedDates ?? this.downloadedDates,
    sharedWithEmails: sharedWithEmails ?? this.sharedWithEmails,
    invitation: invitation ?? this.invitation,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerUid': ownerUid,
    'ownerEmail': ownerEmail,
    'site': site,
    'dates': dates,
    'status': status,
    'alertsEnabled': alertsEnabled,
    'downloadedDates': downloadedDates,
    'sharedWithEmails': sharedWithEmails,
    'invitation': invitation,
  };

  factory TripRecord.fromMap(Map<String, dynamic> map) => TripRecord(
    id: map['id'] as String? ?? '',
    ownerUid: map['ownerUid'] as String? ?? '',
    ownerEmail: map['ownerEmail'] as String? ?? '',
    site: map['site'] as String? ?? '',
    dates: map['dates'] as String? ?? '',
    status: map['status'] as String? ?? 'Request pending',
    alertsEnabled: map['alertsEnabled'] as bool? ?? true,
    downloadedDates: map['downloadedDates'] as String? ?? '',
    sharedWithEmails: (map['sharedWithEmails'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        const [],
    invitation: map['invitation'] as String? ?? 'No invitations yet',
  );
}

/// One condition-change / invitation notification. Stored at
/// `users/{uid}/notifications/{id}` in Firestore, and delivered
/// in-app (via FCM when configured, via the local stream otherwise).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.tripId,
    this.site,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? tripId;
  final String? site;
  final bool read;

  /// Null in local mode when no timestamp was supplied; Firestore
  /// records carry an ISO-8601 string.
  final DateTime? createdAt;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    tripId: tripId,
    site: site,
    read: read ?? this.read,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'tripId': tripId,
    'site': site,
    'read': read,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) =>
      AppNotification(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        tripId: map['tripId'] as String?,
        site: map['site'] as String?,
        read: map['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      );
}
