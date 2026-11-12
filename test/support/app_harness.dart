import 'dart:convert';

import 'package:campready/app.dart';
import 'package:campready/repositories/location_repository.dart';
import 'package:campready/repositories/weather_repository.dart';
import 'package:campready/screens/design_screen.dart';
import 'package:campready/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

final today = DateTime(2026, 11, 11, 10);

class FakeLocation extends Mock implements LocationRepository {}

/// A location repository that answers with [status] and real distances.
FakeLocation fakeLocation([
  LocationStatus status = LocationStatus.granted,
  double latitude = 37.13,
  double longitude = -122.12,
]) {
  final location = FakeLocation();
  when(() => location.currentPosition()).thenAnswer(
    (_) async => status == LocationStatus.granted
        ? LocationResult(status, latitude: latitude, longitude: longitude)
        : LocationResult(status),
  );
  when(() => location.milesBetween(any(), any(), any(), any())).thenAnswer((i) {
    final a = i.positionalArguments.cast<double>();
    final dLat = (a[0] - a[2]) * 69.0;
    final dLng = (a[1] - a[3]) * 55.0;
    return (dLat * dLat + dLng * dLng) / (dLat.abs() + dLng.abs() + 1e-9);
  });
  when(() => location.openAppSettings()).thenAnswer((_) async => true);
  when(() => location.openLocationSettings()).thenAnswer((_) async => true);
  return location;
}

/// Open-Meteo stand-in: returns sunny days for the requested range.
WeatherRepository fakeWeather({bool offline = false}) => WeatherRepository(
  clock: () => today,
  client: MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    final start = DateTime.parse(request.url.queryParameters['start_date']!);
    final end = DateTime.parse(request.url.queryParameters['end_date']!);
    final days = <String>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(d.toIso8601String().substring(0, 10));
    }
    return http.Response(
      jsonEncode({
        'daily': {
          'time': days,
          'weather_code': [for (final _ in days) 0],
          'temperature_2m_max': [for (final _ in days) 70.4],
          'temperature_2m_min': [for (final _ in days) 49.6],
          'precipitation_probability_max': [for (final _ in days) 10],
          'wind_speed_10m_max': [for (final _ in days) 8.0],
        },
      }),
      200,
    );
  }),
);

Future<void> loadFonts() async {
  final loader = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  await loader.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> pumpApp(
  WidgetTester tester,
  CampReadyServices services, {
  String route = '/explore',
  LocationRepository? location,
  WeatherRepository? weather,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await tester.pumpWidget(
    CampReady(
      key: UniqueKey(),
      services: services,
      initialRoute: route,
      locationRepository: location ?? fakeLocation(),
      weatherRepository: weather ?? fakeWeather(),
      clock: () => today,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder.last);
  await tester.pumpAndSettle();
  await tester.tap(finder.last);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Route name of the screen on top.
String screenOf(WidgetTester tester) =>
    tester.widget<DesignScreen>(find.byType(DesignScreen).last).screen.route;

DesignScreen _top(WidgetTester tester) =>
    tester.widget<DesignScreen>(find.byType(DesignScreen).last);

/// Campsite id and trip id of the screen on top.
String? siteOf(WidgetTester tester) => _top(tester).siteId;
String? tripOf(WidgetTester tester) => _top(tester).tripId;

/// Local services with [email] signed up and still signed in.
Future<(CampReadyServices, AppUser)> signedIn([
  String email = 'owner@example.com',
  String name = 'Owner',
]) async {
  final services = CampReadyServices.local();
  final user = await services.auth.signUp(
    email: email,
    password: 'campready123',
    displayName: name,
  );
  return (services, user);
}
