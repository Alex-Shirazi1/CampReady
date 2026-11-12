part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  AppUser? get user => null;

  @override
  List<Object?> get props => [];
}

/// Session not known yet (e.g. Firebase is restoring it).
final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.user, {this.message});

  @override
  final AppUser user;

  /// A non-fatal problem to show once, e.g. a name that did not save.
  final String? message;

  @override
  List<Object?> get props => [user, message];
}

final class AuthUnauthenticated extends AuthState {}

final class AuthFailure extends AuthState {
  AuthFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
