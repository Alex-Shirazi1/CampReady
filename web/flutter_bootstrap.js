{{flutter_js}}
{{flutter_build_config}}

// Load without serviceWorkerSettings. With them (the default bootstrap),
// the loader registers Flutter's deprecated cleanup service worker at "/"
// whenever a worker is already registered there. Here that worker is
// firebase-messaging-sw.js, so the cleanup worker would replace it,
// unregister it (dropping the FCM push subscription) and reload the page.
_flutter.loader.load();
