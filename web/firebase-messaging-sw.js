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

firebase.messaging();
