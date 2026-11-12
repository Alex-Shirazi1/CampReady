# CampReady

Know what to expect before you camp.

CSEN 268 · Group 2 · Atishay Jain and Alexander Shirazi

Flutter implementation of CampReady, with the submitted Figma screens,
Material theme, interactive controls, named routes, and Firebase integration.

## Run

Requires Flutter 3.47.7 / Dart 3.13.5 or a compatible newer stable SDK.

```sh
flutter pub get
flutter run -d chrome
```

The Firebase configuration currently supports web. Live Android and iOS use
requires separate platform registration. For an explicit UI-only preview on
any platform, run with `--dart-define=LOCAL_DEMO=true`.

```sh
flutter analyze
flutter test
flutter build web
```

## Screens and navigation

All **100 Figma frames** have named routes, including the walkthrough guide,
loading/splash variants, and alternative outcomes. [Full route inventory and
screenshots](docs/ROUTES.md). No frame is omitted from the route inventory.

Main flow: animated splash → welcome → guest Explore → campsite → conditions
→ account gate → signup → location demo → Explore → campsite → dates → review
→ simulated booking → trip → share → invitation → accept/decline.

The five tabs are Explore, Trips, Saved, Alerts and Profile. Filters, illustrative
map pins, saved campsites, profile edits, notifications, Plus upgrade/cancellation,
booking outcomes, date error examples, invitation expiry and offline snapshots
are connected. Open **Demo · Guide** from the top of any screen to inspect the
walkthrough or select any prototype screen.

![Welcome](docs/screenshots/welcome.png)
![Explore](docs/screenshots/explore.png)

## First Integrations (CSEN 268, due Nov 12, 2026)

See [setup and verification](docs/FIRST_INTEGRATIONS.md). Email/password auth,
saved campsites, trips, and sharing use Firebase. Data reloads after signing in
and refreshing tabs. Local demo mode is explicit and labeled.

Web push uses the configured public VAPID key and requires browser permission. In-app sample update records do not themselves send push messages.

## Milestone boundaries

Bookings and payments are **simulated**: no charge is made. Demo
state lives in memory and resets on restart; offline summaries are
session previews, not persistent downloads. The map is illustrative.
Dates and forecasts are fixed sample scenarios from the design.

The one-pager's proposed Plus price is **$2.99/month**. Core browsing, conditions
and essential alerts stay free. Device location and live conditions feeds are
later final-project work, not this milestone.

## Design sources

- [Submitted Figma design](https://www.figma.com/design/0fq2beCEORwCjxxgzTkmFA/CampReady)
- Submitted CampReady App One Pager and Hipcamp HW1 review, supplied project pack.
- Roboto; forest `#365744`, warm white `#F7F4EE`, soft green `#EAF0E7`, amber notices.
- Campsite photos, map layers and navigation graphics are downloaded original
  Figma assets. Roboto is bundled locally with its license.

The Figma file contained 100 top-level frames when implemented. Native Flutter
layout adapts the design to scrolling, editable fields and screen width;
screenshots document the coded result.

## Verification and submission

Tests cover signup, booking, sharing, navigation, validation, account restoration,
invitation access, and failure handling. Each of the 100 routes is rendered at
390 × 844 with layout exceptions checked. Service tests using the local store
are separate from live Firebase verification. [Screenshots](docs/screenshots)
show the earlier coded UI snapshot.

Regenerate screenshots explicitly:

```sh
flutter test --dart-define=SCREENSHOTS=true --update-goldens
```

**coded-ui-v1.2** identifies the earlier submitted UI snapshot.

## Code layout

- `lib/theme.dart`: Material colors, typography and control styles.
- `lib/app.dart`: named routes, session state, interactive screens and controls.
- `lib/services/`: First Integrations services — AuthService (Firebase Auth),
  FirestoreService (Cloud Firestore), MessagingService (FCM), plus an
  explicit in-memory demo for previews and tests.
  `lib/firebase_options.dart` contains the web client configuration.
- `lib/screens/` contains the Flutter layouts grouped by feature and the list of named routes.
- `lib/screens.dart` contains the buttons, cards and text styles shared by those screens.
- `assets/images`: local design assets; no temporary Figma URLs at runtime.
- `test/app_test.dart`: navigation, input validation and screen rendering checks.
