part of 'auth_bloc.dart';

sealed class AuthEvent {}

class AuthUserChanged extends AuthEvent {
  AuthUserChanged(this.user);
  final AppUser? user;
}

class AuthSignInRequested extends AuthEvent {
  AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;
}

class AuthSignUpRequested extends AuthEvent {
  AuthSignUpRequested({
    required this.email,
    required this.password,
    this.displayName,
  });
  final String email;
  final String password;
  final String? displayName;
}

class AuthSignOutRequested extends AuthEvent {}

class AuthDisplayNameChanged extends AuthEvent {
  AuthDisplayNameChanged(this.name);
  final String name;
}
