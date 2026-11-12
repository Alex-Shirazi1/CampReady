# Routes

Every screen from the Figma file has a named GoRouter route (`context.goNamed('<name>')`). Paths carry the campsite or trip they show, so links like `/campsite/redwood-grove` or `/trips/<tripId>` open directly on the web and survive a reload.

- **Signed in** routes redirect to the auth gate (`/authgate?from=...`) and return to the original link after sign-in.
- **Demo build** routes are prototype controls. They only open with `--dart-define=SHOW_DEMO=true`; otherwise they redirect to Explore or Welcome.
- Older flat paths such as `/review` or `/ridgetrip` still work and redirect to the full path.
- Trip screens check access: a trip that was removed or revoked opens "This trip is no longer available", and an invitee is sent to their own view of the trip.

Screenshots are regenerated with `flutter test tool/screenshots_test.dart --update-goldens` (add `--dart-define=SHOW_DEMO=true` for the demo screens).

| Screen | Name | Path | Access | Screenshot |
| --- | --- | --- | --- | --- |
| CampReady | `guide` | `/guide` | Demo build | [View](screenshots/guide.png) |
| Alternative paths | `states` | `/states` | Demo build | [View](screenshots/states.png) |
| CampReady | `splash` | `/splash` | Anyone | [View](screenshots/splash.png) |
| Your next weekend, well prepared. | `welcome` | `/welcome` | Anyone | [View](screenshots/welcome.png) |
| Welcome back | `signin` | `/signin` | Anyone | [View](screenshots/signin.png) |
| Welcome back | `signinfilled` | `/signinfilled` | Demo build | [View](screenshots/signinfilled.png) |
| Let’s try that again | `signinerror` | `/signinerror` | Demo build | [View](screenshots/signinerror.png) |
| Make room for outside | `signup` | `/signup` | Anyone | [View](screenshots/signup.png) |
| Make room for outside | `signupfilled` | `/signupfilled` | Demo build | [View](screenshots/signupfilled.png) |
| Check your details | `signuperror` | `/signuperror` | Demo build | [View](screenshots/signuperror.png) |
| Forgot your password? | `forgot` | `/forgot` | Anyone | [View](screenshots/forgot.png) |
| Check your inbox | `resetsent` | `/resetsent` | Anyone | [View](screenshots/resetsent.png) |
| Find your nearby outside | `location` | `/location` | Anyone | [View](screenshots/location.png) |
| Pick your destination | `denied` | `/denied` | Anyone | [View](screenshots/denied.png) |
| Keep your plans together | `authgate` | `/authgate` | Anyone | [View](screenshots/authgate.png) |
| Find your outside. | `explore` | `/explore` | Signed in | [View](screenshots/explore.png) |
| Find your outside. | `guest` | `/guest` | Anyone | [View](screenshots/guest.png) |
| Where are you headed? | `searchguest` | `/searchguest` | Anyone | [View](screenshots/searchguest.png) |
| Where are you headed? | `search` | `/search` | Anyone | [View](screenshots/search.png) |
| Make it your kind of trip | `filters` | `/filters` | Anyone | [View](screenshots/filters.png) |
| Find a place on the map | `map` | `/map` | Anyone | [View](screenshots/map.png) |
| Redwood Grove | `detail` | `/campsite/:siteId` | Anyone | [View](screenshots/detail.png) |
| Redwood Grove | `guestdetail` | redirects to `/campsite/:siteId` | Signed in | [View](screenshots/guestdetail.png) |
| Saved for later | `detailsaved` | `/campsite/:siteId/detailsaved` | Signed in | [View](screenshots/detailsaved.png) |
| Sunset Ridge | `ridge` | redirects to `/campsite/:siteId` | Signed in | [View](screenshots/ridge.png) |
| Review your trip | `ridgereview` | redirects to `/campsite/:siteId/review` | Signed in | [View](screenshots/ridgereview.png) |
| Trip plan saved | `ridgeconfirmed` | redirects to `/campsite/:siteId/confirmed` | Signed in | [View](screenshots/ridgeconfirmed.png) |
| Sunset Ridge | `ridgetrip` | redirects to `/trips/:tripId` | Signed in | [View](screenshots/ridgetrip.png) |
| Trip Conditions | `conditions` | `/campsite/:siteId/conditions` | Anyone | [View](screenshots/conditions.png) |
| Weather for your stay | `weather` | `/campsite/:siteId/weather` | Anyone | [View](screenshots/weather.png) |
| Fire rules | `fire` | `/campsite/:siteId/fire` | Anyone | [View](screenshots/fire.png) |
| Trail & road access | `closures` | `/campsite/:siteId/closures` | Anyone | [View](screenshots/closures.png) |
| Conditions not confirmed | `unknown` | `/campsite/:siteId/unknown` | Anyone | [View](screenshots/unknown.png) |
| Still checking | `unknownretry` | `/campsite/:siteId/unknownretry` | Anyone | [View](screenshots/unknownretry.png) |
| Choose your dates | `dates` | `/campsite/:siteId/dates` | Signed in | [View](screenshots/dates.png) |
| Choose upcoming dates | `dateerror` | `/campsite/:siteId/dateerror` | Demo build | [View](screenshots/dateerror.png) |
| Review and book | `review` | `/campsite/:siteId/review` | Signed in | [View](screenshots/review.png) |
| Stay ahead of changes | `notifprompt` | `/campsite/:siteId/notifprompt` | Signed in | [View](screenshots/notifprompt.png) |
| You’re on your way. | `confirmed` | `/campsite/:siteId/confirmed` | Signed in | [View](screenshots/confirmed.png) |
| Your next outside | `trips` | `/trips` | Signed in | [View](screenshots/trips.png) |
| Redwood Grove | `trip` | `/trips/:tripId` | Signed in | [View](screenshots/trip.png) |
| Your trip conditions | `tripconditions` | `/trips/:tripId/tripconditions` | Signed in | [View](screenshots/tripconditions.png) |
| Dates updated | `tripupdated` | `/trips/:tripId/tripupdated` | Signed in | [View](screenshots/tripupdated.png) |
| Redwood Grove | `updatedplan` | `/trips/:tripId/updatedplan` | Demo build | [View](screenshots/updatedplan.png) |
| Better with your people | `share` | `/trips/:tripId/share` | Signed in | [View](screenshots/share.png) |
| Invitation sent | `shared` | `/trips/:tripId/shared` | Signed in | [View](screenshots/shared.png) |
| Demo trip link | `linkcopied` | `/trips/:tripId/linkcopied` | Signed in | [View](screenshots/linkcopied.png) |
| Remove this trip? | `remove` | `/trips/:tripId/remove` | Signed in | [View](screenshots/remove.png) |
| Your next trip starts here | `tripsempty` | `/tripsempty` | Signed in | [View](screenshots/tripsempty.png) |
| Places worth returning to | `saved` | `/saved` | Signed in | [View](screenshots/saved.png) |
| Save a little inspiration | `savedempty` | `/savedempty` | Signed in | [View](screenshots/savedempty.png) |
| Trip updates | `alerts` | `/alerts` | Signed in | [View](screenshots/alerts.png) |
| A change to your trip | `alertdetail` | `/alertdetail` | Signed in | [View](screenshots/alertdetail.png) |
| Trip notifications | `preferences` | `/preferences` | Signed in | [View](screenshots/preferences.png) |
| Preferences saved | `preferencessaved` | `/preferencessaved` | Signed in | [View](screenshots/preferencessaved.png) |
| All quiet for now | `alertsempty` | `/alertsempty` | Signed in | [View](screenshots/alertsempty.png) |
| Your profile | `profile` | `/profile` | Signed in | [View](screenshots/profile.png) |
| Your profile | `editprofile` | `/editprofile` | Signed in | [View](screenshots/editprofile.png) |
| Profile updated | `profilesaved` | `/profilesaved` | Signed in | [View](screenshots/profilesaved.png) |
| Your profile | `profileupdated` | `/profileupdated` | Signed in | [View](screenshots/profileupdated.png) |
| Sign out of CampReady? | `signout` | `/signout` | Signed in | [View](screenshots/signout.png) |
| More weekends. Less work. | `premium` | `/premium` | Signed in | [View](screenshots/premium.png) |
| Review CampReady Plus | `upgrade` | `/upgrade` | Signed in | [View](screenshots/upgrade.png) |
| Upgrade didn’t go through | `upgradeerror` | `/upgradeerror` | Demo build | [View](screenshots/upgradeerror.png) |
| Welcome to Plus | `upgraded` | `/upgraded` | Signed in | [View](screenshots/upgraded.png) |
| Your membership | `subscription` | `/subscription` | Signed in | [View](screenshots/subscription.png) |
| Hello, John. | `profileplus` | `/profileplus` | Signed in | [View](screenshots/profileplus.png) |
| Cancel CampReady Plus? | `cancelplus` | `/cancelplus` | Signed in | [View](screenshots/cancelplus.png) |
| Membership cancelled | `pluscancelled` | `/pluscancelled` | Signed in | [View](screenshots/pluscancelled.png) |
| About CampReady | `about` | `/about` | Anyone | [View](screenshots/about.png) |
| You’re offline | `offline` | `/offline` | Anyone | [View](screenshots/offline.png) |
| Redwood Grove | `downloaded` | `/trips/:tripId/downloaded` | Signed in | [View](screenshots/downloaded.png) |
| Finding your outside | `loading` | `/loading` | Anyone | [View](screenshots/loading.png) |
| We couldn’t load campsites | `serviceerror` | `/serviceerror` | Demo build | [View](screenshots/serviceerror.png) |
| Complete flow | `choose-your-dates` | `/campsite/:siteId/choose-your-dates` | Demo build | [View](screenshots/choose-your-dates.png) |
| Complete flow | `choose-a-checkout-date` | `/campsite/:siteId/choose-a-checkout-date` | Demo build | [View](screenshots/choose-a-checkout-date.png) |
| Complete flow | `checkout-must-follow-arrival` | `/campsite/:siteId/checkout-must-follow-arrival` | Demo build | [View](screenshots/checkout-must-follow-arrival.png) |
| Complete flow | `those-dates-are-unavailable` | `/campsite/:siteId/those-dates-are-unavailable` | Demo build | [View](screenshots/those-dates-are-unavailable.png) |
| Complete flow | `request-not-sent` | `/campsite/:siteId/request-not-sent` | Signed in | [View](screenshots/request-not-sent.png) |
| Complete flow | `booking-response` | `/trips/:tripId/booking-response` | Demo build | [View](screenshots/booking-response.png) |
| Complete flow | `your-camping-group` | `/trips/:tripId/your-camping-group` | Signed in | [View](screenshots/your-camping-group.png) |
| Complete flow | `you-re-invited` | `/trips/:tripId/you-re-invited` | Signed in | [View](screenshots/you-re-invited.png) |
| Complete flow | `you-joined-the-trip` | `/trips/:tripId/you-joined-the-trip` | Signed in | [View](screenshots/you-joined-the-trip.png) |
| Complete flow | `invitation-declined` | `/invitation-declined` | Anyone | [View](screenshots/invitation-declined.png) |
| Complete flow | `this-invitation-is-unavailable` | `/this-invitation-is-unavailable` | Anyone | [View](screenshots/this-invitation-is-unavailable.png) |
| Complete flow | `invitation-not-sent` | `/trips/:tripId/invitation-not-sent` | Signed in | [View](screenshots/invitation-not-sent.png) |
| Complete flow | `downloaded-summaries` | `/downloaded-summaries` | Signed in | [View](screenshots/downloaded-summaries.png) |
| Complete flow | `save-for-offline-use` | `/trips/:tripId/save-for-offline-use` | Signed in | [View](screenshots/save-for-offline-use.png) |
| Complete flow | `download-failed` | `/trips/:tripId/download-failed` | Demo build | [View](screenshots/download-failed.png) |
| Complete flow | `ready-for-offline-use` | `/trips/:tripId/ready-for-offline-use` | Signed in | [View](screenshots/ready-for-offline-use.png) |
| Complete flow | `no-downloaded-trips` | `/no-downloaded-trips` | Signed in | [View](screenshots/no-downloaded-trips.png) |
| Complete flow | `your-offline-copy-is-older` | `/trips/:tripId/your-offline-copy-is-older` | Signed in | [View](screenshots/your-offline-copy-is-older.png) |
| Complete flow | `this-trip-is-no-longer-available` | `/this-trip-is-no-longer-available` | Anyone | [View](screenshots/this-trip-is-no-longer-available.png) |
| Complete flow | `matching-campsites` | `/matching-campsites` | Anyone | [View](screenshots/matching-campsites.png) |
| Complete flow | `no-matching-campsites` | `/no-matching-campsites` | Anyone | [View](screenshots/no-matching-campsites.png) |
| Complete flow | `location-permission` | `/location-permission` | Demo build | [View](screenshots/location-permission.png) |
| Complete flow | `connection-scenarios` | `/connection-scenarios` | Demo build | [View](screenshots/connection-scenarios.png) |
| Complete flow | `demo-payment-response` | `/demo-payment-response` | Demo build | [View](screenshots/demo-payment-response.png) |
| Complete flow | `enter-a-display-name` | `/enter-a-display-name` | Demo build | [View](screenshots/enter-a-display-name.png) |
| Ready to explore | `splash-ready` | `/splash-ready` | Demo build | [View](screenshots/splash-ready.png) |
