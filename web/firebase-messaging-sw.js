importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAqUGv8lzaFWEG8jrOSo9yM6EoWLW8nlKY',
  appId: '1:555369541366:web:74ac3b724d0c9a46fe46d7',
  messagingSenderId: '555369541366',
  projectId: 'campready-group2',
  authDomain: 'campready-group2.firebaseapp.com',
  storageBucket: 'campready-group2.firebasestorage.app'
});

const messaging = firebase.messaging();

// Background messages on web. A message with a `notification` payload
// (for example a Firebase Console test message) is already shown by the
// Firebase SDK before this handler runs, so showing it here as well
// would display it twice. Only a data-only message, which has no display
// at all otherwise, gets a notification built here.
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const data = payload.data || {};
  return self.registration.showNotification(data.title || 'Trip update', {
    body: data.body || '',
    data,
  });
});

// Tapping a background notification focuses the open app tab, or
// opens CampReady when it is not open.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    }),
  );
});
