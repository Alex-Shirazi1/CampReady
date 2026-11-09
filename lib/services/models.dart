// Plain data models for the First Integrations services layer.
// These are backend-neutral: the same objects are produced by the
// Firestore implementation and by the local in-memory fallback, so
// the UI never branches on which backend is active.

/// Lowercases+trims emails, dropping empties and duplicates (first
/// occurrence wins). Email identity in this app is case-insensitive;
/// Firestore `arrayContains` and the trip read rule are not.
List<String> normalizeEmails(Iterable<String> emails) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in emails) {
    final email = raw.trim().toLowerCase();
    if (email.isEmpty || !seen.add(email)) continue;
    out.add(email);
  }
  return out;
}

/// Parses a stored timestamp that may be an ISO-8601 string (what
/// [AppNotification.toMap] writes), a [DateTime], or a Firestore
/// `Timestamp` (what a console-written doc may carry). Returns null
/// instead of throwing on an unexpected shape, so one malformed doc
/// does not fail a whole list read.
DateTime? parseStoredDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    final dynamic timestamp = value;
    return timestamp.toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}

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
    // Emails are stored lowercased+trimmed everywhere: the Firestore
    // shared-trip query (arrayContains) and the read rule are both
    // case-sensitive, so a mixed-case stored email would hide a trip.
    'email': email.trim().toLowerCase(),
    'displayName': displayName,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String? ?? '',
    email: (map['email'] as String? ?? '').trim().toLowerCase(),
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
    // Normalised at the model boundary (see fromMap): the create rule
    // requires ownerEmail == the auth token email, and the shared query
    // is case-sensitive, so stored emails must be lowercased+trimmed.
    'ownerEmail': ownerEmail.trim().toLowerCase(),
    'site': site,
    'dates': dates,
    'status': status,
    'alertsEnabled': alertsEnabled,
    'downloadedDates': downloadedDates,
    'sharedWithEmails': normalizeEmails(sharedWithEmails),
    'invitation': invitation,
  };

  factory TripRecord.fromMap(Map<String, dynamic> map) => TripRecord(
    id: map['id'] as String? ?? '',
    ownerUid: map['ownerUid'] as String? ?? '',
    ownerEmail: (map['ownerEmail'] as String? ?? '').trim().toLowerCase(),
    site: map['site'] as String? ?? '',
    dates: map['dates'] as String? ?? '',
    status: map['status'] as String? ?? 'Request pending',
    alertsEnabled: map['alertsEnabled'] as bool? ?? true,
    downloadedDates: map['downloadedDates'] as String? ?? '',
    sharedWithEmails: normalizeEmails(
      (map['sharedWithEmails'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    ),
    invitation: map['invitation'] as String? ?? 'No invitations yet',
  );
}

/// One condition-change / invitation notification. A trip notification
/// is stored once at `trips/{tripId}/notifications/{id}` in Firestore
/// (readable by the owner and by invitees) and the owner's own copy
/// at `users/{uid}/notifications/{id}`; FCM foreground saves also go
/// to the signed-in user's own list. Delivered in-app (via FCM when
/// configured, via the local stream otherwise).
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
        createdAt: parseStoredDateTime(map['createdAt']),
      );
}
