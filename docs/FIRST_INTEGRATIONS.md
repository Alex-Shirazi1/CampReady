# First Integrations

CSEN 268 · Group 2 · Assignment 1080282 · Due November 12, 2026, 11:59 PM Pacific

The milestone calls for the first integration of data, messaging, and authentication. The app keeps the submitted Figma screens and ordinary Flutter widgets, named routes, and service classes.

## Run

```sh
flutter pub get
flutter run -d chrome
```

The configured Firebase project is `campready-group2`. Email/password authentication and Cloud Firestore use this project. Only the web app is registered. Android and iOS need their own Firebase app registrations and generated platform options before live use.

Firebase startup failures show a retry screen. They do not silently switch to an in-memory backend.

For the UI preview, explicitly select local demo mode:

```sh
flutter run -d chrome --dart-define=LOCAL_DEMO=true
```

Local demo data disappears on restart. It is not evidence of Firebase persistence or push delivery.

## Data and authentication

- Sign up, sign in, sign out, reset password, and edit the display name.
- Saved campsites and trips persist in Firestore and reload after authentication or tab refresh.
- The owner edits and removes a trip and shares it by email.
- Invitees can read the shared plan and accept or decline. They cannot edit the owner's dates or booking status.
- Refresh retrieves the owner's latest plan. Revocation removes the invitee's access.
- The UI retains one trip per campsite. Conflicting shared trips produce an explicit notice rather than overwriting either record.
- Failed writes remain on the current screen and report an error instead of showing a successful save.

Collections: `users/{uid}` for profiles, with `savedCampsites`, `notifications`, `notificationReads`, and `fcmTokens` subcollections; `trips/{tripId}` for plans, with `responses/{uid}` for invitation responses and `notifications/{id}` for trip notifications.

`firestore.rules` contains the rules used by this revision. Publication to the live project is **not** verified from this repo alone — deploy it and check the console before submission:

```sh
firebase deploy --only firestore:rules --project campready-group2
```

(`.firebaserc` sets `campready-group2` as the default project.) Updating the local file alone does not publish future changes.

Trip creation is create-only. A `set()` on an existing trip is checked by the update rule, not the create rule, so `!exists()` on create cannot catch a second create. Instead `createTrip` writes a server-timestamp `createdAt` and the update rule keeps `createdAt` immutable, so a second create is denied rather than overwriting the trip and wiping its shares. Trip ids must start with `trip_<creator uid>_`, so another account cannot pre-create someone else's trip id. Until the rules in the console match this file, a second create can still overwrite an existing trip.

## Notification delivery

A trip event is written **once** to `trips/{tripId}/notifications/{id}`. The trip owner and everyone in the trip's `sharedWithEmails` can read it, so delivery needs no per-invitee account lookup and no write into another account's `users/{uid}` subtree (which the users rule denies). The owner's own copy also goes to their own `users/{uid}/notifications` list. That is why sharing with an email that has not signed up yet still delivers: the invitee reads the trip notification when they sign in and load the trip.

Delivery is per user. An invitation notice carries `recipientEmail`, so only the invited account sees it, not the other invitees on the same trip. The owner's alert preference controls only the owner's own copy; invitees are still notified. An invitee who declined no longer sees the trip or its notifications.

Read state is per-user: marking a shared trip notification read writes a marker to the reader's own `users/{uid}/notificationReads/{id}`, never to the shared record.

## Messaging

The project’s public Web Push certificate key is configured in the app. For another Firebase project, supply its public key with `FCM_VAPID_KEY`. The key is client configuration, not a server credential. The VAPID key's ownership against this project's Web Push certificate has **not** been verified in the Firebase console — compare it there before submission; a wrong key fails registration at runtime and no local test catches it.

Push registration runs on sign-in (restoring an already-granted registration) and from Save Preferences (which requests permission — a user gesture). The app listens for foreground messages (`onMessage`) and refreshes tokens (`onRegistered` — the firebase_messaging 17 replacement for the deprecated `onTokenRefresh` — old token removed). In the background, the Firebase SDK in `web/firebase-messaging-sw.js` shows messages that carry a `notification` payload, such as a Console test message. The worker's `onBackgroundMessage` builds a notification only for data-only messages, so nothing is shown twice. Tapping a notification the worker built focuses or opens the app; a notification the SDK showed opens its `fcm_options.link` when the message sets one. `onMessageOpenedApp` (open the tapped trip) is wired but fires on mobile only, because FlutterFire's web plugin never emits it. `web/flutter_bootstrap.js` starts Flutter without the deprecated Flutter service worker. The default bootstrap would replace and unregister the FCM worker at `/` on the next page load, which drops the push subscription. The mobile background handler in `lib/main.dart` is registered off-web; the project is web-only, so it has no native Firebase config to initialise with yet.

Permission denial, missing setup, and registration failures are reported separately from saving notification preferences. Signing out detaches the device registration from the account.

Sample booking/date changes create in-app notification records. Those records alone do **not** send FCM pushes. There is no automatic server-side condition-change sender in this revision. A Firebase Console test message is needed to verify actual foreground and background FCM delivery; do not describe a local in-app alert as that test.

## Local Firebase checks

Install Firebase CLI and Java 21, then run:

```sh
firebase emulators:start --only auth,firestore --project demo-campready
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true
```

This uses local Auth on port 9099 and Firestore on port 8080, with the local rules. It uses a separate `demo-campready` project ID. FCM is disabled in emulator mode because Firebase has no FCM emulator.

```sh
flutter analyze
flutter test
flutter build web
```

## Existing prototype boundaries

Bookings, payments, Plus upgrades, location screens, forecasts, and offline summaries retain the submitted sample behavior. No real reservation or charge is made. Offline summaries are session previews. The one-pager's location sensor and live condition data remain final-project work.

## Live acceptance checks

Before submission, verify on the shared Firebase project:

1. Both accounts can sign in; saved campsites and trips survive reload.
2. An owner shares a trip; the recipient accepts, refreshes changed dates, and loses access after revocation.
3. Permission and registration succeed with the configured Web Push key.
4. A real FCM test message arrives with the app open and in the background.
5. If demonstrating on a phone, repeat the relevant checks using that platform's Firebase configuration.
