import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/trips/trips_cubit.dart';
import 'repositories/campsite_repository.dart';
import 'screens.dart';
import 'screens/design_screen.dart';

/// Shows prototype controls (Demo · Guide, simulated failures).
/// Pass --dart-define=SHOW_DEMO=true to turn them on.
const showDemoBuild = bool.fromEnvironment('SHOW_DEMO');

/// Screens under /campsite/:siteId.
const campsiteRoutes = {
  'detail',
  'detailsaved',
  'conditions',
  'weather',
  'fire',
  'closures',
  'unknown',
  'unknownretry',
  'dates',
  'dateerror',
  'review',
  'notifprompt',
  'confirmed',
  'request-not-sent',
  'choose-your-dates',
  'choose-a-checkout-date',
  'checkout-must-follow-arrival',
  'those-dates-are-unavailable',
};

/// Screens under /trips/:tripId.
const tripRoutes = {
  'trip',
  'tripconditions',
  'tripupdated',
  'updatedplan',
  'share',
  'shared',
  'linkcopied',
  'remove',
  'booking-response',
  'your-camping-group',
  'you-re-invited',
  'you-joined-the-trip',
  'invitation-not-sent',
  'downloaded',
  'save-for-offline-use',
  'download-failed',
  'ready-for-offline-use',
  'your-offline-copy-is-older',
};

/// Older route names that now point at one shared screen.
const routeAliases = {
  'guestdetail': 'detail',
  'ridge': 'detail',
  'ridgereview': 'review',
  'ridgeconfirmed': 'confirmed',
  'ridgetrip': 'trip',
};

/// Prototype-only screens, hidden in the normal build.
const demoRoutes = {
  'guide',
  'states',
  'connection-scenarios',
  'demo-payment-response',
  'booking-response',
  'location-permission',
  'signinfilled',
  'signinerror',
  'signupfilled',
  'signuperror',
  'splash-ready',
  'dateerror',
  'choose-your-dates',
  'choose-a-checkout-date',
  'checkout-must-follow-arrival',
  'those-dates-are-unavailable',
  'enter-a-display-name',
  'upgradeerror',
  'updatedplan',
  'serviceerror',
  'download-failed',
};

/// Screens a guest can open without signing in.
const guestRoutes = {
  'guide',
  'states',
  'splash',
  'splash-ready',
  'welcome',
  'signin',
  'signinfilled',
  'signinerror',
  'signup',
  'signupfilled',
  'signuperror',
  'forgot',
  'resetsent',
  'authgate',
  'guest',
  'searchguest',
  'search',
  'filters',
  'map',
  'matching-campsites',
  'no-matching-campsites',
  'location',
  'denied',
  'location-permission',
  'loading',
  'offline',
  'serviceerror',
  'connection-scenarios',
  'about',
  'detail',
  'conditions',
  'weather',
  'fire',
  'closures',
  'unknown',
  'unknownretry',
  'this-trip-is-no-longer-available',
  'this-invitation-is-unavailable',
  'invitation-declined',
};

/// Trip screens an invitee may open.
const inviteeRoutes = {
  'you-re-invited',
  'you-joined-the-trip',
  'tripconditions',
};

class StreamToListenable extends ChangeNotifier {
  StreamToListenable(List<Stream<dynamic>> streams) {
    for (final stream in streams) {
      _subscriptions.add(stream.listen((_) => notifyListeners()));
    }
  }

  final _subscriptions = <StreamSubscription<dynamic>>[];

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}

GoRouter buildRouter({
  required String initialLocation,
  required AuthBloc auth,
  required TripsCubit trips,
  required CampsiteRepository campsites,
}) {
  GoRouterWidgetBuilder builder(CampPage screen) =>
      (context, state) => DesignScreen(
        key: state.pageKey,
        screen: screen,
        siteId: state.pathParameters['siteId'],
        tripId: state.pathParameters['tripId'],
        extra: state.extra,
        from: state.uri.queryParameters['from'],
      );

  GoRoute page(CampPage screen, String path) =>
      GoRoute(path: path, name: screen.route, builder: builder(screen));

  final pages = {for (final p in campPages) p.route: p};
  CampPage named(String route) => pages[route]!;

  String? redirect(BuildContext context, GoRouterState state) {
    final segments = state.uri.pathSegments;
    final name = state.topRoute?.name;
    if (segments.isEmpty) return '/splash';
    final route = name ?? segments.last;
    if (!showDemoBuild && demoRoutes.contains(route)) {
      return auth.state is AuthAuthenticated ? '/explore' : '/welcome';
    }
    if (auth.state is AuthLoading) return null;
    final signedIn = auth.state is AuthAuthenticated;
    final from = Uri.encodeComponent(state.uri.toString());
    if (!guestRoutes.contains(route)) {
      if (auth.state is AuthInitial) return '/splash?from=$from';
      if (!signedIn) return '/authgate?from=$from';
    }
    if (route == 'explore' && !signedIn) return '/guest';
    if (route == 'guest' && signedIn) return '/explore';

    final siteId = state.pathParameters['siteId'];
    if (siteId != null && campsites.byId(siteId) == null) {
      return signedIn ? '/explore' : '/guest';
    }
    final tripId = state.pathParameters['tripId'];
    if (tripId != null && trips.state.isLoaded) {
      final trip = trips.state.byId(tripId);
      if (trip == null) return '/this-trip-is-no-longer-available';
      if (!trip.isOwner && !inviteeRoutes.contains(route)) {
        return '/trips/$tripId/'
            '${trip.myResponse == 'accepted' ? 'you-joined-the-trip' : 'you-re-invited'}';
      }
      if (trip.isOwner &&
          (route == 'you-re-invited' || route == 'you-joined-the-trip')) {
        return '/trips/$tripId';
      }
    }
    return null;
  }

  /// Old flat paths such as /review or /ridgetrip.
  String legacyTarget(String route, GoRouterState state) {
    final canonical = routeAliases[route] ?? route;
    final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
    if (campsiteRoutes.contains(canonical)) {
      final site = route.startsWith('ridge') ? 'sunset-ridge' : 'redwood-grove';
      final suffix = canonical == 'detail' ? '' : '/$canonical';
      return '/campsite/$site$suffix$query';
    }
    final owned = trips.state.trips.where((t) => t.isOwner);
    final first = owned.isNotEmpty
        ? owned.first
        : trips.state.trips.isEmpty
        ? null
        : trips.state.trips.first;
    if (first == null) {
      return trips.state.isLoaded
          ? '/this-trip-is-no-longer-available'
          : '/trips$query';
    }
    final suffix = canonical == 'trip' ? '' : '/$canonical';
    return '/trips/${first.id}$suffix$query';
  }

  final flat = campPages.where(
    (p) =>
        !campsiteRoutes.contains(p.route) &&
        !tripRoutes.contains(p.route) &&
        !routeAliases.containsKey(p.route) &&
        p.route != 'trips',
  );

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: StreamToListenable([auth.stream, trips.stream]),
    redirect: redirect,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      for (final screen in flat) page(screen, '/${screen.route}'),
      GoRoute(
        path: '/campsite/:siteId',
        name: 'detail',
        builder: builder(named('detail')),
        routes: [
          for (final route in campsiteRoutes.where((r) => r != 'detail'))
            page(named(route), route),
        ],
      ),
      GoRoute(
        path: '/trips',
        name: 'trips',
        builder: builder(named('trips')),
        routes: [
          GoRoute(
            path: ':tripId',
            name: 'trip',
            builder: builder(named('trip')),
            routes: [
              for (final route in tripRoutes.where((r) => r != 'trip'))
                page(named(route), route),
            ],
          ),
        ],
      ),
      for (final route in {
        ...campsiteRoutes,
        ...tripRoutes,
        ...routeAliases.keys,
      })
        if (route != 'trips')
          GoRoute(
            path: '/$route',
            redirect: (_, state) => legacyTarget(route, state),
          ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/welcome'),
          child: const Text('Return to CampReady'),
        ),
      ),
    ),
  );
}
