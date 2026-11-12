import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:campready/blocs/auth/auth_bloc.dart';
import 'package:campready/repositories/auth_repository.dart';
import 'package:campready/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const user = AppUser(uid: 'u1', email: 'a@example.com', displayName: 'A');
  late MockAuthRepository repo;
  late StreamController<AppUser?> changes;

  setUp(() {
    repo = MockAuthRepository();
    changes = StreamController<AppUser?>.broadcast();
    when(() => repo.userChanges).thenAnswer((_) => changes.stream);
    when(() => repo.saveProfile(any())).thenAnswer((_) async {});
  });
  setUpAll(() => registerFallbackValue(user));
  tearDown(() => changes.close());

  test('starts unknown until the session is restored', () {
    expect(AuthBloc(repo).state, isA<AuthInitial>());
  });

  blocTest<AuthBloc, AuthState>(
    'restored session emits authenticated',
    build: () => AuthBloc(repo),
    act: (_) => changes.add(user),
    expect: () => [AuthAuthenticated(user)],
  );

  blocTest<AuthBloc, AuthState>(
    'no session emits unauthenticated',
    build: () => AuthBloc(repo),
    act: (_) => changes.add(null),
    expect: () => [AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'sign in success saves the profile',
    setUp: () => when(
      () => repo.signIn(email: 'a@example.com', password: 'campready123'),
    ).thenAnswer((_) async => user),
    build: () => AuthBloc(repo),
    act: (bloc) => bloc.add(
      AuthSignInRequested(email: 'a@example.com', password: 'campready123'),
    ),
    expect: () => [AuthLoading(), AuthAuthenticated(user)],
    verify: (_) => verify(() => repo.saveProfile(user)).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'wrong password emits the readable error',
    setUp: () => when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthException('Check your email and password')),
    build: () => AuthBloc(repo),
    act: (bloc) =>
        bloc.add(AuthSignInRequested(email: 'a@example.com', password: 'nope')),
    expect: () => [AuthLoading(), AuthFailure('Check your email and password')],
  );

  blocTest<AuthBloc, AuthState>(
    'a profile write failure does not fail sign up',
    setUp: () {
      when(
        () => repo.signUp(
          email: 'a@example.com',
          password: 'campready123',
          displayName: 'A',
        ),
      ).thenAnswer((_) async => user);
      when(() => repo.saveProfile(any())).thenThrow(Exception('offline'));
    },
    build: () => AuthBloc(repo),
    act: (bloc) => bloc.add(
      AuthSignUpRequested(
        email: 'a@example.com',
        password: 'campready123',
        displayName: 'A',
      ),
    ),
    expect: () => [AuthLoading(), AuthAuthenticated(user)],
  );

  blocTest<AuthBloc, AuthState>(
    'network error on sign up shows a connection message',
    setUp: () => when(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenThrow(TimeoutException('slow')),
    build: () => AuthBloc(repo),
    act: (bloc) => bloc.add(
      AuthSignUpRequested(email: 'a@example.com', password: 'campready123'),
    ),
    expect: () => [
      AuthLoading(),
      AuthFailure(
        'Could not create the account. Check your connection and try again.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'sign out goes through the repository',
    setUp: () => when(() => repo.signOut()).thenAnswer((_) async {}),
    build: () => AuthBloc(repo),
    seed: () => AuthAuthenticated(user),
    act: (bloc) => bloc.add(AuthSignOutRequested()),
    expect: () => [AuthLoading(), AuthUnauthenticated()],
    verify: (_) => verify(() => repo.signOut()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'display name change emits the updated user',
    setUp: () =>
        when(() => repo.updateDisplayName('Alex'))
            .thenAnswer((_) async => user.copyWith(displayName: 'Alex')),
    build: () => AuthBloc(repo),
    seed: () => AuthAuthenticated(user),
    act: (bloc) => bloc.add(AuthDisplayNameChanged('Alex')),
    expect: () => [AuthAuthenticated(user.copyWith(displayName: 'Alex'))],
  );

  blocTest<AuthBloc, AuthState>(
    'display name failure keeps the user and reports it',
    setUp: () =>
        when(() => repo.updateDisplayName('Alex')).thenThrow(Exception('x')),
    build: () => AuthBloc(repo),
    seed: () => AuthAuthenticated(user),
    act: (bloc) => bloc.add(AuthDisplayNameChanged('Alex')),
    expect: () => [
      AuthAuthenticated(
        user,
        message: 'Your name could not be saved. Check your connection.',
      ),
    ],
  );
}
