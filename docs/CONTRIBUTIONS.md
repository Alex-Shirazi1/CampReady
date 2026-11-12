# Contributions

Group 2 · CSEN 268 Fall 2026 · Repository: https://github.com/Alex-Shirazi1/CampReady

We split the work about evenly. Alexander built the app's foundation: the coded UI for all 100 designed screens, the navigation, and the first Firebase integration. Atishay built the final-project layer on top of it: BLoC architecture, sensors, the push backend, the mobile platforms, and testing. We shared the idea, the design, the slides, the video and the presentation.

## By area

| Area | Alexander Shirazi (`Alex-Shirazi1`) | Atishay Jain (`Atishay8192261`) |
| --- | --- | --- |
| Idea and design | App idea, one-pager and Figma screens (shared) | App idea, one-pager and Figma screens (shared) |
| Coded UI | Built all 100 Figma screens in Flutter with named routes and working navigation | Animated splash, app icon, launch screens, clearer errors and copy |
| Firebase | Firebase Auth, Firestore data model and security rules, first FCM web push and service worker | Android and iOS Firebase config, emulator setup, Cloud Functions for user-specific push |
| Trips and sharing | Trip history and removal, trip sharing between accounts and the matching Firestore rules | Real date picker and booking flow, invite accept and decline, owner view of responses, revoke |
| Architecture | Repository layout and screen structure the final app builds on | BLoC and Cubits with RepositoryProvider, GoRouter paths, deep links and the auth gate |
| Sensors and live data | | GPS distance sort with permission fallbacks, camera profile photo, Open-Meteo forecast |
| Testing | _Alexander: add your device and user testing_ | 235 automated tests, an on-device integration test, and the live two-account test |
| Deployment | Repository owner, pull request reviews and merges, Blaze plan and Cloud Functions deploy | Firebase Hosting deploys of the web app |
| Presentation | _Slides and video: add your parts_ | _Slides and video: add your parts_ |

## From git

- **Alexander:** 5 commits (Oct 30–Nov 8). They added most of the original codebase: about 29,000 lines across the screens, navigation and Firebase integration.
- **Atishay:** 50+ commits (Nov 1–12). They reworked that codebase for the final project: about 18,000 lines added and 28,000 removed.

### Alexander's commits

| Date | Commit |
| --- | --- |
| 2026-10-30 | Build CampReady screens and working navigation |
| 2026-11-01 | Fix trip history and removal state handling |
| 2026-11-05 | Add Firebase Auth, Firestore, and messaging |
| 2026-11-08 | Fix Firebase create, sharing, and notifications |
| 2026-11-08 | Fix push, trip rules, and notifications |

### Atishay's commits, by area

| Area | Commits |
| --- | --- |
| State management | Add bloc packages, Add campsite and stay models, Add repositories, Add cubits and blocs, Move screens to blocs |
| Routing | Fix web deep links, Send demo links to splash, Open shared trip for invite links, Add route render tests |
| Sensors | Add photo repository, Add profile photo camera, Add platform permissions, Fix Android location fallback, Recheck location before settings |
| Messaging backend | Add push cloud functions, Open trip from web push, Skip iOS push without APNs, Send pushes by FID |
| Data and sync | Add weather repository, Rain-aware forecast headline, Refresh lists on tab change, Fix night count, Hide alerts before invite |
| Platforms | Add Android Firebase config, Add iOS Firebase config, Pin iOS packages, Emulator host for Android tests, Use platform config in emulators |
| Look and feel | Add CampReady app icon, Match launch screen colors, Clearer sign-in errors, Fix copy and web location retry |
| Testing | Add bloc tests, Add repository tests, Update tests for blocs, Add route render tests, Add integration test |
| Deliverables | Add screenshot generator, Refresh screenshots, Add store screenshots, README and docs |
