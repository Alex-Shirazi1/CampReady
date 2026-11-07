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

Collections: `users/{uid}` for profiles, with `savedCampsites`, `notifications`, and `fcmTokens` subcollections; `trips/{tripId}` for plans, with `responses/{uid}` for invitation responses.

`firestore.rules` contains the rules used by this revision, published to the project on November 7, 2026. Updating this local file alone does not publish future changes.

## Messaging

The project’s public Web Push certificate key is configured in the app. For another Firebase project, supply its public key with `FCM_VAPID_KEY`. The key is client configuration, not a server credential. The web service worker handles background notification delivery; the app listens for foreground messages and stores received messages for the signed-in account.

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
