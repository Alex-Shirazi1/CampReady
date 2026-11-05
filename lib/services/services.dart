// The CampReady services container for First Integrations.
// One shared LocalStore backs all three services in local mode; in
// configured mode the same services talk to Firebase Auth, Cloud
// Firestore and Firebase Cloud Messaging.

import 'auth_service.dart';
import 'backend.dart';
import 'firestore_service.dart';
import 'local_store.dart';
import 'messaging_service.dart';

export 'auth_service.dart';
export 'firestore_service.dart';
export 'local_store.dart';
export 'messaging_service.dart';
export 'models.dart';

class CampReadyServices {
  CampReadyServices._({
    required this.auth,
    required this.firestore,
    required this.messaging,
    required this.store,
  });

  /// Local-mode container: no Firebase, in-memory store only.
  factory CampReadyServices.local() {
    final store = LocalStore();
    final firestore = FirestoreService(store: store, useFirebase: false);
    return CampReadyServices._(
      auth: AuthService(store: store, useFirebase: false),
      firestore: firestore,
      messaging: MessagingService(
        store: store,
        firestore: firestore,
        useFirebase: false,
      ),
      store: store,
    );
  }

  /// Tries Firebase first; falls back to local mode on any failure
  /// (no configuration, no network, missing native config). Never
  /// throws, so app start never depends on Firebase being ready.
  static Future<CampReadyServices> initialize() async {
    final configured = await FirebaseBackend.initialize();
    if (!configured) return CampReadyServices.local();
    final store = LocalStore();
    final firestore = FirestoreService(store: store, useFirebase: true);
    final services = CampReadyServices._(
      auth: AuthService(store: store, useFirebase: true),
      firestore: firestore,
      messaging: MessagingService(
        store: store,
        firestore: firestore,
        useFirebase: true,
      ),
      store: store,
    );
    await services.messaging.initialize();
    return services;
  }

  final AuthService auth;
  final FirestoreService firestore;
  final MessagingService messaging;
  final LocalStore store;

  /// 'firebase' once Firebase.initializeApp() has succeeded,
  /// otherwise 'local' (in-memory, clearly labelled in the UI).
  String get mode => auth.useFirebase ? 'firebase' : 'local';

  bool get isFirebaseConfigured => auth.useFirebase;
}
