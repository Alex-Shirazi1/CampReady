import '../models/stay.dart';

/// Lowercases and trims emails, dropping empties and duplicates.
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

/// Accepts an ISO string, a DateTime or a Firestore Timestamp.
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

class AppUser {
  const AppUser({required this.uid, required this.email, this.displayName});

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
    'email': email.trim().toLowerCase(),
    'displayName': displayName,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String? ?? '',
    email: (map['email'] as String? ?? '').trim().toLowerCase(),
    displayName: map['displayName'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);
}

/// Stored at users/{uid}/savedCampsites/{siteId}.
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

/// Stored at trips/{tripId}. Invitees are listed by email.
class TripRecord {
  const TripRecord({
    required this.id,
    required this.ownerUid,
    required this.ownerEmail,
    required this.site,
    required this.dates,
    this.siteId = '',
    this.stay,
    this.status = 'Request pending',
    this.alertsEnabled = true,
    this.downloadedDates = '',
    this.sharedWithEmails = const [],
    this.invitation = 'No invitations yet',
  });

  static String idFor(String ownerUid, String siteName) =>
      'trip_${ownerUid}_${siteName.replaceAll(' ', '_')}';

  final String id;
  final String ownerUid;
  final String ownerEmail;
  final String site;
  final String siteId;

  /// Display label. Older trips only have this text, not [stay].
  final String dates;
  final Stay? stay;
  final String status;
  final bool alertsEnabled;
  final String downloadedDates;
  final List<String> sharedWithEmails;
  final String invitation;

  TripRecord copyWith({
    Stay? stay,
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
    siteId: siteId,
    dates: stay?.label ?? dates,
    stay: stay ?? this.stay,
    status: status ?? this.status,
    alertsEnabled: alertsEnabled ?? this.alertsEnabled,
    downloadedDates: downloadedDates ?? this.downloadedDates,
    sharedWithEmails: sharedWithEmails ?? this.sharedWithEmails,
    invitation: invitation ?? this.invitation,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerUid': ownerUid,
    'ownerEmail': ownerEmail.trim().toLowerCase(),
    'site': site,
    'siteId': siteId,
    'dates': dates,
    ...?stay?.toMap(),
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
    siteId: map['siteId'] as String? ?? '',
    dates: map['dates'] as String? ?? '',
    stay: Stay.fromMap(map),
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

/// One trip update or invitation. Trip-wide copies live at
/// trips/{tripId}/notifications/{id}; the owner's copy at
/// users/{uid}/notifications/{id}.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.tripId,
    this.site,
    this.recipientEmail,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? tripId;
  final String? site;

  /// Set when the notice is for one invitee only.
  final String? recipientEmail;
  final bool read;
  final DateTime? createdAt;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    tripId: tripId,
    site: site,
    recipientEmail: recipientEmail,
    read: read ?? this.read,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'tripId': tripId,
    'site': site,
    if (recipientEmail != null) 'recipientEmail': recipientEmail,
    'read': read,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    tripId: map['tripId'] as String?,
    site: map['site'] as String?,
    recipientEmail: (map['recipientEmail'] as String?)?.trim().toLowerCase(),
    read: map['read'] as bool? ?? false,
    createdAt: parseStoredDateTime(map['createdAt']),
  );

  @override
  bool operator ==(Object other) =>
      other is AppNotification && other.id == id && other.read == read;

  @override
  int get hashCode => Object.hash(id, read);
}
