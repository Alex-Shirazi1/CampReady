// Push notifications for CampReady trips.
// The app writes trip updates to Firestore; these triggers send them to
// the right people through Firebase Cloud Messaging.

const { setGlobalOptions } = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

// Keep costs at zero: small, short-lived functions, nothing kept warm.
setGlobalOptions({
  maxInstances: 2,
  minInstances: 0,
  memory: "256MiB",
  timeoutSeconds: 30,
});
initializeApp();

const db = getFirestore();
const SITE = "https://campready-group2.web.app";

/** Firebase uids for the given emails; unknown emails are skipped. */
async function uidsForEmails(emails) {
  const unique = [...new Set(emails.map((e) => e.trim().toLowerCase()))];
  if (unique.length === 0) return [];
  const result = await getAuth().getUsers(unique.map((email) => ({ email })));
  return result.users.map((user) => user.uid);
}

/** Sends one push to every saved device of each user who has alerts on. */
async function sendToUsers(uids, { id, title, body, tripId, site }) {
  let sent = 0;
  for (const uid of uids) {
    const profile = await db.doc(`users/${uid}`).get();
    if (profile.get("alertsEnabled") === false) {
      logger.info("Alerts off, skipping", { uid });
      continue;
    }
    // The app saves each device's Firebase Installation ID (FID).
    const fidDocs = await db.collection(`users/${uid}/fcmTokens`).get();
    const fids = fidDocs.docs.map((doc) => doc.id);
    if (fids.length === 0) {
      logger.info("No device registered", { uid });
      continue;
    }
    const response = await getMessaging().sendEachForMulticast({
      fids,
      notification: { title, body },
      // notificationId lets the app match the push to the saved notice.
      data: { notificationId: id || "", tripId: tripId || "", site: site || "" },
      webpush: tripId ? { fcmOptions: { link: `${SITE}/trips/${tripId}` } } : undefined,
    });
    sent += response.successCount;
    // Forget devices that uninstalled the app or revoked permission.
    await Promise.all(
      response.responses.map((r, i) => {
        const code = r.error && r.error.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          return db.doc(`users/${uid}/fcmTokens/${fids[i]}`).delete();
        }
        if (r.error) logger.warn("Send failed", { uid, code });
        return null;
      }),
    );
  }
  return sent;
}

/**
 * A trip update or invitation was saved. Invitations go to the invited
 * email only; other updates go to everyone the trip is shared with.
 * The owner made the change, so the owner gets no push.
 */
exports.pushTripNotification = onDocumentCreated(
  "trips/{tripId}/notifications/{notificationId}",
  async (event) => {
    const note = event.data && event.data.data();
    if (!note) return;
    const { tripId } = event.params;
    const trip = await db.doc(`trips/${tripId}`).get();
    if (!trip.exists) return;
    const emails = note.recipientEmail
      ? [note.recipientEmail]
      : trip.get("sharedWithEmails") || [];
    const uids = await uidsForEmails(emails);
    const sent = await sendToUsers(uids, {
      id: event.params.notificationId,
      title: note.title,
      body: note.body,
      tripId,
      site: note.site || trip.get("site"),
    });
    logger.info("Trip update pushed", { tripId, recipients: uids.length, sent });
  },
);

/** An invitee accepted or declined: tell the trip owner. */
exports.pushInviteResponse = onDocumentWritten(
  "trips/{tripId}/responses/{uid}",
  async (event) => {
    const after = event.data && event.data.after.data();
    if (!after) return;
    const before = event.data.before.data();
    if (before && before.status === after.status) return;
    const { tripId } = event.params;
    const trip = await db.doc(`trips/${tripId}`).get();
    if (!trip.exists) return;
    const ownerUid = trip.get("ownerUid");
    const site = trip.get("site");
    const title = `${after.email} ${after.status} your invitation`;
    const body = `${site} · ${trip.get("dates")}`;
    const id = `response_${tripId}_${event.params.uid}_${Date.now()}`;
    await db.doc(`users/${ownerUid}/notifications/${id}`).set({
      id,
      title,
      body,
      tripId,
      site,
      read: false,
      createdAt: new Date().toISOString(),
      sentAt: FieldValue.serverTimestamp(),
    });
    const sent = await sendToUsers([ownerUid], {
      id,
      title,
      body,
      tripId,
      site,
    });
    logger.info("Invite response pushed", { tripId, sent });
  },
);
