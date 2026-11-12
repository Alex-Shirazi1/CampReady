import '../services/services.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._messaging);

  final AuthService _auth;
  final FirestoreService _firestore;
  final MessagingService _messaging;

  bool get usesFirebase => _auth.useFirebase;

  AppUser? get currentUser => _auth.currentUser;

  /// Emits the current user first, then every sign-in and sign-out.
  Stream<AppUser?> get userChanges async* {
    if (!_auth.useFirebase) yield _auth.currentUser;
    yield* _auth.authStateChanges;
  }

  Future<AppUser> signIn({required String email, required String password}) =>
      _auth.signIn(email: email, password: password);

  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _auth.signUp(email: email, password: password, displayName: displayName);

  Future<void> saveProfile(AppUser user) => _firestore.saveUserProfile(user);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  Future<AppUser?> updateDisplayName(String name) async {
    final updated = await _auth.updateDisplayName(name);
    if (updated != null) await _firestore.saveUserProfile(updated);
    return updated;
  }

  /// Removes this device's push token before signing out.
  Future<void> signOut() async {
    try {
      await _messaging.detachUser();
    } catch (_) {
      // Signing out must still work offline; the stale token is
      // cleaned up by the backend when a send fails.
    }
    await _auth.signOut();
  }
}
