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

// Background messages on web: show the notification. Without this
// handler a data-only message has no display at all, and a
// notification-payload message only gets the browser default.
messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'Trip update';
  const options = {
    body: (payload.notification && payload.notification.body) || '',
    data: payload.data || {},
  };
  return self.registration.showNotification(title, options);
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
