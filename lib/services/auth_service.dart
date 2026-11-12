// Email/password sign-in with Firebase Auth, or LocalStore in local mode.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'local_store.dart';
import 'models.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  AuthService({required this._store, required this.useFirebase});

  final LocalStore _store;
  final bool useFirebase;

  AppUser? _currentUser;
  final _controller = StreamController<AppUser?>.broadcast();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Current signed-in user, null when signed out. In configured mode
  /// this mirrors FirebaseAuth.currentUser.
  AppUser? get currentUser {
    if (useFirebase) {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    }
    return _currentUser;
  }

  bool get isSignedIn => currentUser != null;

  /// Emits the signed-in user (or null) on every sign-in / sign-out.
  Stream<AppUser?> get authStateChanges {
    if (useFirebase) {
      return fb.FirebaseAuth.instance.authStateChanges().map(
        (user) => user == null
            ? null
            : AppUser(
                uid: user.uid,
                email: user.email ?? '',
                displayName: user.displayName,
              ),
      );
    }
    return _controller.stream;
  }

  void _emit(AppUser? user) {
    _currentUser = user;
    if (!_controller.isClosed) _controller.add(user);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(normalized)) {
      throw const AuthException('Enter a valid email');
    }
    if (password.length < 8) {
      throw const AuthException('Use at least 8 characters');
    }
    if (useFirebase) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: normalized,
              password: password,
            );
        final name = displayName?.trim();
        if (name != null && name.isNotEmpty) {
          await credential.user?.updateDisplayName(name);
        }
        final user = currentUser!;
        _emit(user);
        return user;
      } on fb.FirebaseAuthException catch (e) {
        throw AuthException(_friendly(e));
      }
    }
    if (_store.findUser(normalized) != null) {
      throw const AuthException('An account already exists for that email');
    }
    final user = _store.createUser(normalized, password, displayName);
    _emit(user);
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(normalized)) {
      throw const AuthException('Enter a valid email');
    }
    if (useFirebase) {
      try {
        await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalized,
          password: password,
        );
        final user = currentUser!;
        _emit(user);
        return user;
      } on fb.FirebaseAuthException catch (e) {
        throw AuthException(_friendly(e));
      }
    }
    final user = _store.findUser(normalized);
    if (user == null || !_store.checkPassword(normalized, password)) {
      throw const AuthException('Check your email and password');
    }
    _emit(user);
    return user;
  }

  Future<void> signOut() async {
    if (useFirebase) {
      await fb.FirebaseAuth.instance.signOut();
    }
    _emit(null);
  }

  /// Sends a password-reset email in configured mode. In local mode
  /// no email is sent; the request is recorded locally only.
  Future<void> sendPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(normalized)) {
      throw const AuthException('Enter a valid email');
    }
    if (useFirebase) {
      try {
        await fb.FirebaseAuth.instance.sendPasswordResetEmail(
          email: normalized,
        );
      } on fb.FirebaseAuthException catch (e) {
        throw AuthException(_friendly(e));
      }
      return;
    }
    _store.recordPasswordReset(normalized);
  }

  Future<AppUser?> updateDisplayName(String displayName) async {
    final user = currentUser;
    if (user == null) return null;
    final name = displayName.trim();
    if (name.isEmpty) return user;
    if (useFirebase) {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      await fbUser?.updateDisplayName(name);
      // reload() so the name read back below is the saved one, not the
      // stale pre-update value.
      await fbUser?.reload();
      final updated = currentUser;
      _emit(updated);
      return updated;
    }
    final updated = _store.updateDisplayName(user.uid, name);
    _emit(updated);
    return updated;
  }

  static String _friendly(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email';
      case 'invalid-email':
        return 'Enter a valid email';
      case 'weak-password':
        return 'Use at least 8 characters';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Check your email and password';
      case 'too-many-requests':
        return 'Too many attempts. Wait a minute and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'user-disabled':
        return 'This account is disabled.';
      default:
        final message = e.message?.trim() ?? '';
        return message.length > 8
            ? message
            : 'Sign-in failed. Check your email and password, then try again.';
    }
  }
}
