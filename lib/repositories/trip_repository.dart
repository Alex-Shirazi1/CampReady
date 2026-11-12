import 'package:equatable/equatable.dart';

import '../models/stay.dart';
import '../services/services.dart';

class InviteResponse extends Equatable {
  const InviteResponse(this.email, this.status);
  final String email;
  final String status;

  @override
  List<Object?> get props => [email, status];
}

/// A trip as the signed-in account sees it.
class TripView extends Equatable {
  const TripView({
    required this.record,
    required this.isOwner,
    this.myResponse,
    this.responses = const [],
  });

  final TripRecord record;
  final bool isOwner;

  /// The invitee's own answer: null, 'accepted' or 'declined'.
  final String? myResponse;

  /// Answers from current invitees, for the owner.
  final List<InviteResponse> responses;

  String get id => record.id;

  String get people {
    if (!isOwner) {
      return myResponse == 'accepted'
          ? 'You joined the trip'
          : 'Invitation pending';
    }
    if (record.sharedWithEmails.isEmpty) {
      return record.invitation == 'Invitation revoked'
          ? 'Invitation revoked'
          : 'No invitations yet';
    }
    return record.sharedWithEmails
        .map((email) {
          final answer = responses.where((r) => r.email == email);
          return '$email: ${answer.isEmpty ? 'pending' : answer.first.status}';
        })
        .join('\n');
  }

  TripView copyWith({TripRecord? record}) => TripView(
    record: record ?? this.record,
    isOwner: isOwner,
    myResponse: myResponse,
    responses: responses,
  );

  @override
  List<Object?> get props => [
    record.id,
    record.dates,
    record.status,
    record.sharedWithEmails,
    record.invitation,
    record.downloadedDates,
    record.alertsEnabled,
    isOwner,
    myResponse,
    responses,
  ];
}

class TripRepository {
  TripRepository(this._firestore, this._messaging);

  final FirestoreService _firestore;
  final MessagingService _messaging;

  /// Owned trips plus trips shared with [user]. Declined invitations
  /// are left out.
  Future<List<TripView>> tripsFor(AppUser user) async {
    final records = await _firestore.tripsForUser(user.uid, user.email);
    final views = <TripView>[];
    for (final record in records) {
      if (record.ownerUid == user.uid) {
        List<Map<String, String>> answers;
        try {
          answers = await _firestore.invitationResponses(record.id);
        } catch (_) {
          answers = const [];
        }
        views.add(
          TripView(
            record: record,
            isOwner: true,
            responses: [
              for (final a in answers)
                if (record.sharedWithEmails.contains(a['email']))
                  InviteResponse(a['email']!, a['status'] ?? 'pending'),
            ],
          ),
        );
      } else {
        Map<String, String>? answer;
        try {
          answer = await _firestore.invitationResponse(record.id, user.uid);
        } catch (_) {
          answer = null;
        }
        if (answer?['status'] == 'declined') continue;
        views.add(
          TripView(
            record: record,
            isOwner: false,
            myResponse: answer?['status'],
          ),
        );
      }
    }
    views.sort((a, b) {
      final sa = a.record.stay?.checkIn, sb = b.record.stay?.checkIn;
      if (sa == null || sb == null) {
        return a.record.site.compareTo(b.record.site);
      }
      return sa.compareTo(sb);
    });
    return views;
  }

  Future<TripRecord> create(TripRecord trip) => _firestore.createTrip(trip);

  Future<void> update(TripRecord trip) => _firestore.updateTrip(trip);

  Future<void> delete(String tripId) => _firestore.deleteTrip(tripId);

  Future<TripRecord> share(TripRecord trip, String email) =>
      _firestore.shareTrip(tripId: trip.id, email: email);

  Future<TripRecord> revoke(TripRecord trip) =>
      _firestore.revokeInvitations(trip);

  Future<void> respond(TripRecord trip, AppUser user, bool accept) => _firestore
      .respondToInvitation(trip, user, accept ? 'accepted' : 'declined');

  /// Writes the invitation notice the invitee reads from the trip.
  Future<void> notifyShared(TripRecord trip, String inviteeEmail) =>
      _messaging.notifyTripShared(
        ownerUid: trip.ownerUid,
        ownerEmail: trip.ownerEmail,
        inviteeEmail: inviteeEmail,
        tripId: trip.id,
        site: trip.site,
      );

  /// Writes a trip update for the owner (when [notifyOwner]) and the group.
  Future<AppNotification> notifyChange(
    TripRecord trip, {
    required String title,
    required String body,
    required bool notifyOwner,
  }) => _messaging.notifyConditionChange(
    ownerUid: trip.ownerUid,
    ownerEmail: trip.ownerEmail,
    tripId: trip.id,
    site: trip.site,
    title: title,
    body: body,
    sharedWithEmails: trip.sharedWithEmails,
    notifyOwner: notifyOwner,
  );

  static TripRecord newTrip({
    required AppUser owner,
    required String siteId,
    required String siteName,
    required Stay stay,
    required bool alerts,
  }) => TripRecord(
    id: TripRecord.idFor(owner.uid, siteName),
    ownerUid: owner.uid,
    ownerEmail: owner.email,
    site: siteName,
    siteId: siteId,
    dates: stay.label,
    stay: stay,
    alertsEnabled: alerts,
  );
}
