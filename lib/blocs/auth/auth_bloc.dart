import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/auth_repository.dart';
import '../../services/services.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthDisplayNameChanged>(_onDisplayNameChanged);
    _subscription = authRepository.userChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  final AuthRepository authRepository;
  late final StreamSubscription<AppUser?> _subscription;

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      if (state is! AuthFailure) emit(AuthUnauthenticated());
      return;
    }
    // A sign-in in progress emits its own result.
    if (state is AuthLoading) return;
    emit(AuthAuthenticated(user));
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      await _saveProfile(user);
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(
        AuthFailure('Could not sign in. Check your connection and try again.'),
      );
    }
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      await _saveProfile(user);
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(
        AuthFailure(
          'Could not create the account. Check your connection and try again.',
        ),
      );
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await authRepository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onDisplayNameChanged(
    AuthDisplayNameChanged event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    try {
      final updated = await authRepository.updateDisplayName(event.name);
      emit(AuthAuthenticated(updated ?? current.user));
    } catch (_) {
      emit(
        AuthAuthenticated(
          current.user,
          message: 'Your name could not be saved. Check your connection.',
        ),
      );
    }
  }

  /// The users/{uid} profile is best effort: a failure must not undo
  /// a successful sign-in.
  Future<void> _saveProfile(AppUser user) async {
    try {
      await authRepository.saveProfile(user);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
