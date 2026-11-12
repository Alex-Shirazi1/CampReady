# Presentation outline (15–20 minutes)

Use screenshots from `docs/screenshots/store/` and run the live demo on the Android emulator or the web app.

| # | Slide | Time | Speaker | Content |
| --- | --- | --- | --- | --- |
| 1 | CampReady | 0:30 | Atie | Name, tagline, team, animated splash. |
| 2 | The problem | 1:30 | Alex | Five tabs before every trip: booking, weather, fire notices, group chat. Plans change and someone misses it. |
| 3 | Who it's for | 1:00 | Alex | Weekend campers who plan with friends or family. |
| 4 | Live demo | 6:00 | Atie | Flow below. |
| 5 | Architecture | 2:00 | Atie | BLoC + repositories + GoRouter + Firebase diagram from the README. |
| 6 | Sensors | 1:30 | Alex | GPS: permission states and distance sort. Camera: profile photo, stored as a small JPEG in Firestore. |
| 7 | Messaging | 2:00 | Atie | FCM tokens per device, two Cloud Functions, alerts preference, tap opens the trip. NotificationsBloc + BlocListener. |
| 8 | Data and security | 1:00 | Alex | Firestore collections and the rules that keep trips private to the owner and invitees. |
| 9 | Testing | 1:00 | Atie | 234 tests: bloc_test, repositories with mocktail, widget flows, every route rendered. |
| 10 | Monetization | 1:00 | Alex | Free core; Plus at $2.99/month for multiple trips and offline summaries; booking referrals later. |
| 11 | What's next | 1:00 | Alex | Real campground and fire-restriction data, Google Maps, iOS push with an APNs key, live trip sync. |
| 12 | Thanks / Q&A | 1:00 | Both | |

## Demo flow (6 minutes)

1. Cold start: animated splash, then Welcome.
2. Sign in. Explore → **Use my location** → campsites sorted by distance.
3. Open Redwood Grove → live forecast → Trip Conditions (fire ban, packing tip).
4. **Check availability** → date picker (past dates are greyed out) → review total → **Request to book**.
5. Trip → **Share & group** → invite the second account.
6. On the second device: the push arrives → tap → **Accept invitation**.
7. Back on the owner: Alerts shows "accepted your invitation"; edit the dates; the invitee gets a push.
8. Profile → **Take photo** with the camera.
9. Open `https://campready-group2.web.app/trips/<id>` in a new tab to show deep linking.

## Grading map

| Rubric item | Where we show it |
| --- | --- |
| Authentication | Sign-in, validation, reset email, session restore |
| Sensor usage | GPS distance sort, camera photo |
| Data services | Firestore trips, sharing, rules; Open-Meteo forecast |
| Messaging | Cloud Functions → FCM to the right user; tap opens the trip |
| Animations | Splash, Shimmer loading, page transitions |
| Screen transitions / routing | GoRouter paths, deep links, auth gate |
| Monetization | Plus paywall (simulated) |
