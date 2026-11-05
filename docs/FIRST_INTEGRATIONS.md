# First Integrations — CSEN 268, assignment 1080282

Due Thu Nov 12, 2026, 11:59pm · 20 pts · 25% of Project Management.
Deck definition, the only one that exists (no Canvas rubric was found
in the exhaustive Nov 5 Camino scrape): **"First App integration of
data, messaging, auth."**

## Live Firebase project — real, created Nov 5, 2026

- **Project:** CampReady — **project ID `campready-group2`**,
  project number `555369541366`
- **Note:** a duplicate project `campready-csen268-group2` was created
  in parallel by mistake on Nov 5 and was deleted by Alex the same
  day. Do NOT use or recreate it; `campready-group2` is the only
  live project.
- **Owner account:** alexxshirazi@gmail.com (Alex Shirazi, sole Owner).
  **NOT** ashirazi@scu.edu — SCU Workspace blocks that account from
  creating Google Cloud projects
  (`FAILED_PRECONDITION: Cloud Resource Manager project creation is
  disabled`), and alexxredjaian@gmail.com was blocked by Firebase's
  MFA/2SV requirement. RELIF's Website (`relif-s-website`) was not
  touched.
- **Plan:** Spark — **$0/month, no billing account, no payment info**,
  Analytics off / not linked.
- **Auth:** Email/Password enabled only; all other providers disabled.
- **Firestore:** production mode, location **nam5 (US)**, default
  database, Standard.
- **Web app:** 'CampReady Web',
  App ID `1:555369541366:web:74ac3b724d0c9a46fe46d7`
- **Web config** (client config, same as the console shows):
  ```dart
  apiKey: 'AIzaSyAqUGv8lzaFWEG8jrOSo9yM6EoWLW8nlKY',
  authDomain: 'campready-group2.firebaseapp.com',
  projectId: 'campready-group2',
  storageBucket: 'campready-group2.firebasestorage.app',
  messagingSenderId: '555369541366',
  appId: '1:555369541366:web:74ac3b724d0c9a46fe46d7',
  ```
  This is wired into `lib/firebase_options.dart`
  (`kFirebaseOptionsConfigured = true`). Only the Web app is
  registered so far; no Android/iOS app yet.
- **Cloud Messaging:** FCM API (V1) Enabled, legacy API Disabled.
  No message sent, no Web Push key yet.

### Firestore rules — APPLIED Nov 5, 12:33pm (verified after reload) — BUT THE TRIPS CREATE RULE IS BROKEN, CORRECTED RULES BELOW

The console rules were published Nov 5, 12:33pm, replacing the deny-all default. The published rules are exactly the ones below, so a signed-in user can now read/write their own data in live mode:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /trips/{tripId} {
      allow read: if request.auth != null &&
        (resource.data.ownerUid == request.auth.uid ||
         request.auth.token.email in resource.data.sharedWithEmails);
      allow create: if request.auth != null &&
        request.data.ownerUid == request.auth.uid;
      allow update, delete: if request.auth != null &&
        resource.data.ownerUid == request.auth.uid;
    }
  }
}
```
Note: `request.auth.token.email` requires the user's email in the
token; if sharing reads fail, check membership in a Cloud Function
instead. Do NOT leave the database on test-mode / wide-open rules.

#### ⚠️ ROOT CAUSE FOUND Nov 5 (loop test): `request.data` is not valid in Cloud Firestore rules

Live REST tests (Nov 5, reproduced 4+ times) show owner create of a
trip — minimal doc with only `ownerUid`, and full app-shaped doc —
is denied 403 PERMISSION_DENIED, while `users/{uid}` profile writes
pass and unauthenticated / other-user denials behave correctly. The
published rules text matches the intended text exactly (console
re-check Nov 5, 12:51–12:53pm), so this is NOT a typo in the
published text — it is a bug in the rule expression itself:

- Cloud Firestore rules have **no `request.data` property**.
  Incoming document data is `request.resource.data` (Firebase docs:
  "Allow creation if the current user owns the new document:
  `allow create: if request.auth.uid == request.resource.data.author_uid;`").
  `request.data` is Realtime Database style. Accessing the undefined
  property errors during rule evaluation, and a rule that errors
  **denies** — so every trip create fails, and reads/deletes of a
  non-existent trip doc fail the same way (`resource.data` on a
  missing document errors too).
- The code is NOT at fault: `FirestoreService.createTrip` writes to
  the top-level `trips` collection with `TripRecord.toMap()`, which
  includes `ownerUid` and `sharedWithEmails`, exactly as the rules
  expect. Field names and collection path match.

**CORRECTED RULES — apply in Firebase Console → Firestore → Rules
(the parent applies these; do not edit the console from code):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /trips/{tripId} {
      allow read: if request.auth != null &&
        (resource.data.ownerUid == request.auth.uid ||
         request.auth.token.email in resource.data.get('sharedWithEmails', []));
      allow create: if request.auth != null &&
        request.resource.data.ownerUid == request.auth.uid;
      allow update, delete: if request.auth != null &&
        resource.data.ownerUid == request.auth.uid;
    }
  }
}
```
Changes vs the published version: (1) `request.data.ownerUid` →
`request.resource.data.ownerUid` in `allow create` — this is the
fix; (2) `resource.data.sharedWithEmails` →
`resource.data.get('sharedWithEmails', [])` in `allow read`, so a
trip doc without that field does not error the read rule.
After applying, re-run the live trip test: owner create → 200,
owner read → 200, shared-user read → 200, other-user read → 403.

#### Firebase init timeout (fixed in code Nov 5)

`FirebaseBackend.initialize()` now times out after 10s and falls
back to local mode (see `lib/services/backend.dart`). Previously,
when the Firebase JS SDK could not be fetched (gstatic unreachable
in this VM), the init Future never resolved, `main()` never reached
`runApp`, and the app hung blank. Covered by
`test/firebase_backend_timeout_test.dart` (3 tests).


## What was integrated

| Area | Configured mode (Firebase, live) | Local mode (fallback, if init fails) |
| --- | --- | --- |
| Auth | Firebase Auth, email/password: sign-up, sign-in, sign-out, password reset, `authStateChanges` stream | Same API, in-memory store (`lib/services/local_store.dart`). Accounts live only on this device. |
| Data | Cloud Firestore: `users/{uid}` profile, `users/{uid}/savedCampsites`, top-level `trips` (owner + `sharedWithEmails`), `users/{uid}/notifications`, `users/{uid}/fcmTokens` | Same API, same shapes, in-memory store. |
| Messaging | Firebase Cloud Messaging (v17: `register()` + `onRegistered` yield the Firebase Installation ID, saved under `users/{uid}/fcmTokens`), foreground `onMessage` listener | Permission granted in-app, token is a `local-token-<uid>` identifier, condition changes delivered immediately in-app. No push leaves the device. |

Wiring in the app (`lib/app.dart`):

- Sign-in / sign-up go through `AuthService`. The profile screen
  shows the signed-in account's name/email from Auth/Firestore —
  there is no hardcoded sample name any more.
- "Save campsite" writes to Firestore `savedCampsites` (auth-gated,
  as before).
- Creating / editing / removing a trip and sharing/inviting go
  through `FirestoreService` trips. A shared trip is visible to the
  invitee by email (`tripsForUser` returns owned + shared trips).
- The Alerts screen renders real notification records from
  `MessagingService` / Firestore, plus a line stating the delivery
  mode (FCM vs local). Date changes and booking-status changes
  create condition-change notifications.
- Booking stays simulated ("Prototype only · No charge", no payment).
  Weather / park data stays clearly labelled sample data. All 100
  routes and the 5-tab navigation are unchanged.

## How the app decides which mode it is in

`main.dart` calls `CampReadyServices.initialize()`, which tries
`Firebase.initializeApp()` with the real options in
`lib/firebase_options.dart` and falls back to local mode on any
failure. `CampReadyServices.mode` is `'firebase'` or `'local'`.
With the real config present, the app should start in `'firebase'`
mode when the network and the project are reachable; if init fails
(no network, bad config) it still falls back to local mode and the
UI works end to end.

## Going live — remaining steps (project already exists)

The project, Auth, Firestore and web app above are already made.
What is still left, in order:

1. **Apply the CORRECTED Firestore rules from the section above**
   (`request.resource.data.ownerUid`, not `request.data.ownerUid` —
   the 12:33pm published rules deny all trip creates; see root-cause
   note). Then re-run the live trip create/read/share check.
2. **Cloud Messaging**: no console setup is needed for the app to
   request a token. To actually send pushes when a trip's conditions
   change, add a Firebase Cloud Function (or a small server) that
   watches `users/{uid}/notifications` writes and sends an FCM
   message to that user's saved tokens in `users/{uid}/fcmTokens`.
   That server-side send is *not* part of this milestone — the app
   already writes the notification record and delivers it in-app.
   On web, FCM registration needs a VAPID key (Cloud Messaging →
   Web Push certificates) passed to `register(vapidKey: ...)`.
   Note: Cloud Functions are *not applicable* on the Spark plan
   (free tier is on Blaze, which needs a card) — so true background
   push would require Blaze; do not present push as live-complete.
3. **Invite Atishay** at the very end only, from Project Settings →
   Users and permissions. His Google email is still unknown — do
   not invite anyone until Alex provides it.
4. Rebuild and verify live mode (see "How to verify live mode"
   below): sign up with a fresh email, save a campsite, create a
   trip, share it with your teammate's email, and confirm the trip
   appears for them and a notification record appears in Firestore.
   Delete any test accounts/documents you create for verification.

## How to verify live mode

```
flutter pub get
flutter analyze
flutter test
flutter build web
flutter run -d chrome
```
In the running app, the mode is shown by `CampReadyServices.mode`
(`'firebase'` = live, `'local'` = fallback). Checks:
- Sign up with a fresh email → user appears in Firebase Console →
  Authentication → Users.
- Save a campsite → document appears under
  `users/{uid}/savedCampsites` in Firestore (only after the rules
  above are applied).
- Create a trip, share it with the teammate's email → trip appears
  for that user; a notification record appears under
  `users/{uid}/notifications` on a date/status change.
- Restart the app / open on another device → sign-in persists and
  the same trips/campsites load (this is what local mode cannot do).

## Verification (re-run after the config change)

```
flutter analyze
flutter test        # baseline was 138 tests: 128 pre-existing + 10 new First Integrations tests
flutter build web
```

See README.md for the current counts.
