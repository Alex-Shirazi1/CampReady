# Video script (about 5 minutes)

Record the Android emulator (or a phone) for the main flow and a second device or browser for the invitee. Upload to YouTube as **Unlisted** and paste the link in Camino.

Before recording:

- Two accounts (owner and friend), each signed in on its own device.
- Notifications allowed on both devices (Profile → Notification preferences → Save).
- The owner has no trip at Redwood Grove yet.

| Time | On screen | Voiceover |
| --- | --- | --- |
| 0:00 | App launch, splash | "This is CampReady. It helps weekend campers know what to expect before they go, and plan the trip with their group." |
| 0:15 | Welcome → Sign in | "We sign in with Firebase Authentication. The session stays after a restart." |
| 0:30 | Explore → Use my location → permission | "CampReady asks for location only when you want it, then sorts campsites by distance using the phone's GPS." |
| 0:50 | Open Redwood Grove | "Each campsite shows a live forecast from Open-Meteo, plus fire rules and road access." |
| 1:10 | Trip Conditions | "For trip dates within two weeks you see each day, with a packing tip for the weather." |
| 1:30 | Check availability → date picker | "Dates come from a real date picker. Past dates can't be picked, and checkout has to be after arrival." |
| 1:50 | Review → Request to book | "Booking is simulated for this project; no payment is taken. The trip is saved to Cloud Firestore." |
| 2:10 | Trip → Share & group → invite | "Now I invite my friend by email. A Cloud Function sees the invitation and sends a push to their devices." |
| 2:30 | Second device: push arrives → tap | "On my friend's phone the notification arrives. Tapping it opens the trip." |
| 2:45 | Accept invitation | "They accept. That triggers a second function that tells me, the owner." |
| 3:00 | Owner: Alerts → group | "Here's the update in Alerts, and the group shows they accepted." |
| 3:15 | Edit dates | "If I change the dates, everyone on the trip gets a push with the new dates." |
| 3:35 | Preferences off | "If someone turns trip alerts off, the backend skips them." |
| 3:50 | Profile → Take photo | "The camera is our second sensor: a profile photo, resized and stored with the account." |
| 4:10 | Browser: /trips/<id> | "On the web every screen has its own address, so a trip link opens straight to the trip, or to sign-in first." |
| 4:30 | Architecture slide | "Under the hood: BLoC and Cubits for state, repositories for data, GoRouter for navigation, and Firebase for auth, data and messaging." |
| 4:50 | End card | "That's CampReady. Thanks for watching." |
