// Happy path on a real device or emulator, with the in-memory backend:
//   flutter test integration_test/app_test.dart -d <device>
import 'package:campready/app.dart';
import 'package:campready/models/stay.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  if (finder.evaluate().isEmpty) {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.last);
  await tester.pumpAndSettle();
  await tester.tap(finder.last);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> enter(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
  await tester.pumpAndSettle();
}

/// Taps [day] in the date range picker, which lists this month first.
Future<void> tapDay(WidgetTester tester, DateTime day, DateTime today) async {
  final index = day.month == today.month ? 0 : 1;
  await tester.tap(find.text('${day.day}').at(index));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign up, find a campsite, book dates, open the trip', (
    tester,
  ) async {
    final services = CampReadyServices.local();
    await tester.pumpWidget(CampReady(services: services));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Your next weekend,\nwell prepared.'), findsOneWidget);

    await tap(tester, 'Sign in');
    await tap(tester, 'New to CampReady?  ›');
    await enter(tester, 'Your name', 'Test Camper');
    await enter(tester, 'Email', 'camper@example.com');
    await enter(tester, 'Password', 'campready123');
    await tap(tester, 'Create account');
    expect(find.text('Find your nearby outside'), findsOneWidget);

    await tap(tester, 'Enter a destination instead');
    await tap(tester, 'Santa Cruz  ›');
    expect(find.text('Search results'), findsOneWidget);
    await tap(tester, 'Redwood Grove');
    expect(find.text('Your campsite'), findsOneWidget);

    await tap(tester, 'Check availability');
    expect(find.text('No dates selected'), findsOneWidget);

    final today = dateOnly(DateTime.now());
    final arrive = today.add(const Duration(days: 3));
    final leave = today.add(const Duration(days: 5));
    await tap(tester, 'Choose dates');
    await tapDay(tester, arrive, today);
    await tapDay(tester, leave, today);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final label = Stay(arrive, leave).label;
    expect(find.text(label), findsOneWidget);

    await tap(tester, 'Use selected dates');
    expect(
      find.text(r'2 nights × $65 = $130 · Simulated, no charge'),
      findsOneWidget,
    );
    await tap(tester, 'Request to book');
    expect(find.text('Request sent'), findsOneWidget);

    await tap(tester, 'View trip');
    expect(find.text(label), findsOneWidget);
    final user = services.auth.currentUser!;
    final trips = await services.firestore.tripsForUser(user.uid, user.email);
    expect(trips.single.stay, Stay(arrive, leave));
  });
}
