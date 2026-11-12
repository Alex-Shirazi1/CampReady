import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:campready/blocs/notifications/notifications_bloc.dart';
import 'package:campready/repositories/notification_repository.dart';
import 'package:campready/services/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  const user = AppUser(uid: 'u1', email: 'a@example.com');
  const stored = AppNotification(
    id: 'n1',
    title: 'Redwood Grove: dates changed',
    body: 'Your trip dates are now Dec 12–14, 2026.',
    tripId: 't1',
  );
  const push = AppNotification(
    id: 'm1',
    title: 'You were invited to Sunset Ridge',
    body: 'owner@example.com invited you.',
    tripId: 't2',
  );
  late MockNotificationRepository repo;
  late StreamController<AppNotification> messages;
  late StreamController<AppNotification> opened;

  setUpAll(() => registerFallbackValue(user));
  setUp(() {
    repo = MockNotificationRepository();
    messages = StreamController.broadcast();
    opened = StreamController.broadcast();
    when(() => repo.onMessage).thenAnswer((_) => messages.stream);
    when(() => repo.onMessageOpenedApp).thenAnswer((_) => opened.stream);
    when(() => repo.initialMessage()).thenAnswer((_) async => null);
    when(() => repo.load(any(), tripIds: any(named: 'tripIds')))
        .thenAnswer((_) async => [stored]);
  });
  tearDown(() {
    messages.close();
    opened.close();
  });

  blocTest<NotificationsBloc, NotificationsState>(
    'start loads the saved updates',
    build: () => NotificationsBloc(repo),
    act: (b) => b.add(NotificationsStarted(user, tripIds: {'t1'})),
    expect: () => [
      const NotificationsState(items: [stored]),
    ],
    verify: (_) => verify(() => repo.load(user, tripIds: {'t1'})).called(1),
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'a foreground push is added on top and marked onMessage',
    build: () => NotificationsBloc(repo),
    act: (b) async {
      b.add(NotificationsStarted(user));
      await Future<void>.delayed(Duration.zero);
      messages.add(push);
    },
    skip: 1,
    expect: () => [
      const NotificationsState(
        items: [push, stored],
        latest: push,
        latestType: NotificationType.onMessage,
        received: 1,
      ),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'a tapped notification is marked onMessageOpenedApp',
    build: () => NotificationsBloc(repo),
    act: (b) async {
      b.add(NotificationsStarted(user));
      await Future<void>.delayed(Duration.zero);
      opened.add(push);
    },
    skip: 1,
    expect: () => [
      const NotificationsState(
        items: [push, stored],
        latest: push,
        latestType: NotificationType.onMessageOpenedApp,
        received: 1,
      ),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'the message that launched the app is handled as a background message',
    setUp: () =>
        when(() => repo.initialMessage()).thenAnswer((_) async => push),
    build: () => NotificationsBloc(repo),
    act: (b) => b.add(NotificationsStarted(user)),
    expect: () => [
      const NotificationsState(items: [stored]),
      const NotificationsState(
        items: [push, stored],
        latest: push,
        latestType: NotificationType.onBackgroundMessage,
        received: 1,
      ),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'messages after sign out are ignored',
    build: () => NotificationsBloc(repo),
    act: (b) async {
      b.add(NotificationsStarted(user));
      await Future<void>.delayed(Duration.zero);
      b.add(NotificationsStopped());
      await Future<void>.delayed(Duration.zero);
      messages.add(push);
    },
    expect: () => [
      const NotificationsState(items: [stored]),
      const NotificationsState(),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'a failed load keeps the list and reports it',
    setUp: () =>
        when(() => repo.load(any(), tripIds: any(named: 'tripIds')))
            .thenThrow(Exception('offline')),
    build: () => NotificationsBloc(repo),
    act: (b) => b.add(NotificationsStarted(user)),
    expect: () => [
      const NotificationsState(error: 'Could not load trip updates.'),
    ],
  );

  test('remote messages carry the trip id for routing', () {
    final note = NotificationRepository.fromRemote(
      const RemoteMessage(
        messageId: 'x',
        data: {'tripId': 'trip_1', 'site': 'Redwood Grove'},
        notification: RemoteNotification(title: 'Hi', body: 'There'),
      ),
    );
    expect(note.id, 'x');
    expect(note.tripId, 'trip_1');
    expect(note.title, 'Hi');
  });
}
