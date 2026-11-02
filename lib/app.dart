import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

import 'screens.dart';
import 'campsite_map.dart';

/// Session-only sample state. No account, booking, email or charge is sent.
class TripDetails {
  String dates = 'Oct 30–Nov 1, 2026', status = 'Request pending';
  String invitation = 'No invitations yet', downloadedDates = '';
}

class DemoState {
  bool signedIn = false, saved = false, plus = false, alerts = true;
  bool editingTrip = false;
  bool? bookingAlerts;
  String? bookingDates;
  String destination = '';
  String site = 'Redwood Grove', name = 'John', email = 'john.doe@example.com';
  final details = <String, TripDetails>{};
  TripDetails get trip => details.putIfAbsent(site, TripDetails.new);
  final Set<String> trips = {};
  Iterable<String> get downloads =>
      trips.where((site) => details[site]?.downloadedDates.isNotEmpty == true);
  String siteType = 'Tent',
      travelers = '2 travelers',
      budget = 'Any budget',
      pets = 'Pet friendly';
}

class CampReady extends StatefulWidget {
  const CampReady({
    super.key,
    this.initialRoute = '/splash',
    this.initialState,
  });
  final String initialRoute;
  final DemoState? initialState;
  @override
  State<CampReady> createState() => _CampReadyState();
}

class _CampReadyState extends State<CampReady> {
  late final demo = widget.initialState ?? DemoState();
  late final router = GoRouter(
    initialLocation: widget.initialRoute,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      for (final s in campPages)
        GoRoute(
          path: '/${s.route}',
          name: s.route,
          builder: (_, _) =>
              DesignScreen(key: ValueKey(s.route), screen: s, demo: demo),
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
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'CampReady',
    debugShowCheckedModeBanner: false,
    theme: campTheme(),
    routerConfig: router,
    builder: (context, child) => ColoredBox(
      color: const Color(0xFFE6E9E2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    ),
  );
}

class DesignScreen extends StatefulWidget {
  const DesignScreen({super.key, required this.screen, required this.demo});
  final CampPage screen;
  final DemoState demo;
  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

class _DesignScreenState extends State<DesignScreen>
    with SingleTickerProviderStateMixin
    implements PageControls {
  AnimationController? splashAnimation;
  final fields = <String, String>{};
  final form = GlobalKey<FormState>();
  Timer? timer;
  String? draftDates;
  bool? draftAlerts;
  @override
  bool get ridgeMatch => d.siteType == 'RV' && d.pets == 'Any policy';
  String get route => widget.screen.route;
  DemoState get d => widget.demo;
  String get tripRoute => d.site == 'Sunset Ridge' ? 'ridgetrip' : 'trip';
  String get reviewRoute => d.site == 'Sunset Ridge' ? 'ridgereview' : 'review';
  @override
  void initState() {
    super.initState();
    if (route.startsWith('splash')) {
      splashAnimation = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward();
    }
    if (route.startsWith('splash') || route == 'loading') {
      timer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          context.goNamed(route == 'loading' ? 'explore' : 'welcome');
        }
      });
    }
  }

  @override
  void dispose() {
    splashAnimation?.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  void goTo(String target) {
    if (target == 'profile' && d.plus) target = 'profileplus';
    if (target == 'trips' && d.trips.isEmpty) target = 'tripsempty';
    if (target == 'alerts' && (d.trips.isEmpty || !d.alerts)) {
      target = 'alertsempty';
    }
    if (target == 'explore' && guest) target = 'guest';
    context.pushNamed(target);
  }

  @override
  String get destination => d.destination;

  @override
  void back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(guest ? 'guest' : 'explore');
    }
  }

  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  bool get guest => !d.signedIn;

  @override
  void act(String label, [String? destination]) {
    if (label == '‹ Back' || label == 'Back') {
      back();
      return;
    }
    if (label == 'Sign in' || label == 'Create account') {
      if (route == 'welcome' || route == 'authgate') {
        goTo(label == 'Sign in' ? 'signin' : 'signup');
        return;
      }
      if (!(form.currentState?.validate() ?? true)) {
        return;
      }
      d.signedIn = true;
      d.name = fields['Your name'] ?? d.name;
      d.email = fields['Email'] ?? d.email;
      goTo('location');
      return;
    }
    if (label == 'Send reset link' ||
        label == 'Send invitation' ||
        label == 'Save profile') {
      if (!(form.currentState?.validate() ?? true)) {
        return;
      }
      if (label == 'Save profile') {
        d.name = fields['Display name'] ?? d.name;
        goTo('profilesaved');
      }
      if (label == 'Send reset link') {
        goTo('resetsent');
      }
      if (label == 'Send invitation') {
        d.trip.invitation =
            'Invitation pending · ${fields['Invitation email'] ?? 'friend@example.com'}';
        goTo('shared');
      }
      return;
    }
    if (label == 'Sign out' && route == 'signout') {
      d.signedIn = false;
      context.goNamed('welcome');
      return;
    }
    if (label == 'Get started' || label == 'Explore as a guest') {
      d.signedIn = false;
      goTo('guest');
      return;
    }
    if (label == 'Empty trips') {
      d.trips.clear();
      d.details.clear();
    }
    if (label == 'Empty saved' ||
        label == 'Remove Redwood Grove' ||
        label == 'Remove from saved') {
      d.saved = false;
    }
    if (label == 'Save campsite') {
      if (guest) {
        goTo('authgate');
      } else {
        d.saved = true;
        goTo('detailsaved');
      }
      return;
    }
    if ([
      'Plan this trip',
      'Plan a trip here',
      'Check availability',
      'Plan with these conditions',
    ].contains(label)) {
      if (guest) {
        goTo('authgate');
      } else {
        d.editingTrip = false;
        d.bookingAlerts = d.alerts;
        d.bookingDates = d.trip.dates;
        goTo('dates');
      }
      return;
    }
    if (label == 'Trip Conditions' || label == 'View conditions') {
      goTo(d.site == 'Sunset Ridge' ? 'unknown' : 'conditions');
      return;
    }
    if (label == 'Enable trip updates' && guest) {
      goTo('authgate');
      return;
    }
    if (label == 'Edit dates') {
      d.editingTrip = true;
      d.bookingDates = d.trip.dates;
      goTo('dates');
      return;
    }
    if (label.startsWith('October ')) {
      setState(() {
        draftDates = label == 'October 23–25'
            ? 'Oct 23–25, 2026'
            : 'Oct 30–Nov 1, 2026';
      });
      return;
    }
    if (label == 'Use selected dates') {
      d.bookingDates = draftDates ?? d.bookingDates ?? d.trip.dates;
      if (d.editingTrip) d.trip.dates = d.bookingDates!;
      goTo(d.editingTrip ? 'tripupdated' : reviewRoute);
      return;
    }
    if (label == 'Allow notifications' || label == 'Not now') {
      d.bookingAlerts = label == 'Allow notifications';
      goTo(reviewRoute);
      return;
    }
    if (label == 'Request to book · Demo' || label == 'Retry request') {
      if (d.trips.isNotEmpty && !d.trips.contains(d.site) && !d.plus) {
        goTo('premium');
        return;
      }
      d.trips.add(d.site);
      d.alerts = d.bookingAlerts ?? d.alerts;
      d.bookingAlerts = null;
      d.trip.dates = d.bookingDates ?? d.trip.dates;
      d.bookingDates = null;
      d.trip.status = 'Request pending';
      goTo(d.site == 'Sunset Ridge' ? 'ridgeconfirmed' : 'confirmed');
      return;
    }
    if (label == 'Remove trip' && route == 'remove') {
      d.trips.remove(d.site);
      d.details.remove(d.site);
      goTo(d.trips.isEmpty ? 'tripsempty' : 'trips');
      return;
    }
    if (label == 'Host accepts' ||
        label == 'Host declines' ||
        label == 'No response in 24 hours' ||
        label == 'Request again') {
      setState(
        () => d.trip.status = {
          'Host accepts': 'Accepted',
          'Host declines': 'Declined',
          'No response in 24 hours': 'Expired',
          'Request again': 'Request pending',
        }[label]!,
      );
      notice('Demo booking: ${d.trip.status}');
      return;
    }
    if (label == 'Accept invitation') {
      d.trip.invitation = 'Friend joined';
      goTo('you-joined-the-trip');
      return;
    }
    if (label == 'Decline invitation') {
      d.trip.invitation = 'Invitation declined';
      goTo('invitation-declined');
      return;
    }
    if (label == 'Revoke invitation') {
      d.trip.invitation = 'Invitation revoked';
      goTo('this-invitation-is-unavailable');
      return;
    }
    if (label == 'Refresh shared plan') {
      notice('Demo shared plan refreshed: ${d.trip.dates}');
      setState(() {});
      return;
    }
    if (label == 'Upgrade succeeds') {
      d.plus = true;
    }
    if (label == 'Cancel membership') {
      d.plus = false;
    }
    if (label == 'Download summary' ||
        label == 'Refresh download' ||
        label == 'Refresh while online') {
      goTo(d.plus ? 'save-for-offline-use' : 'premium');
      return;
    }
    if (label == 'Complete download') {
      d.trip.downloadedDates = d.trip.dates;
    }
    if (label == 'Delete downloaded copy') {
      d.trip.downloadedDates = '';
      goTo(
        d.downloads.isEmpty ? 'no-downloaded-trips' : 'downloaded-summaries',
      );
      return;
    }
    if (label == 'Show matching campsites') {
      goTo(
        !(ridgeMatch || d.siteType == 'Tent' && d.travelers == '2 travelers') ||
                d.budget == 'Under \$55'
            ? 'no-matching-campsites'
            : 'matching-campsites',
      );
      return;
    }
    if (label == 'Reset filters') {
      setState(() {
        d.siteType = 'Tent';
        d.travelers = '2 travelers';
        d.budget = 'Any budget';
        d.pets = 'Pet friendly';
      });
      if (destination != null) goTo(destination);
      return;
    }
    if (label == 'Santa Cruz' || label == 'Boulder Creek') {
      d.destination = label;
      goTo(guest ? 'guest' : 'explore');
      return;
    }
    if (label == 'Clear search') {
      setState(() => d.destination = '');
      return;
    }
    if (label == 'Show campsites' || label == 'Search campsites') {
      d.destination = (fields['Destination'] ?? d.destination).trim();
      goTo(guest ? 'guest' : 'explore');
      return;
    }
    if ((label == 'Redwood Grove' || label == 'Sunset Ridge') &&
        route == 'trips') {
      d.site = label;
      goTo(tripRoute);
      return;
    }
    if (label == 'Sunset Ridge') {
      d.site = 'Sunset Ridge';
    }
    if (label == 'Campsite card' || label == 'Redwood Grove') {
      d.site = 'Redwood Grove';
    }
    if (label == 'Explore and plan' ||
        label == 'Trips and group sharing' ||
        label == 'Account and Plus') {
      d.signedIn = true;
    }
    if (label == 'Trips and group sharing') {
      d.site = 'Redwood Grove';
      d.trips.add(d.site);
    }
    if (label == 'Open downloaded trip' && d.downloads.isNotEmpty) {
      if (!d.downloads.contains(d.site)) d.site = d.downloads.first;
      goTo(
        d.trip.downloadedDates == d.trip.dates
            ? 'downloaded'
            : 'your-offline-copy-is-older',
      );
      return;
    }
    if (label == 'Save preferences') d.alerts = draftAlerts ?? d.alerts;
    if (label == 'Redwood: fire restriction') d.site = 'Redwood Grove';
    if (label == 'Sunset: conditions unconfirmed') d.site = 'Sunset Ridge';
    if (label == 'View affected trip') d.site = 'Redwood Grove';
    if (label == 'View trips' ||
        label == 'Your trips' ||
        label == 'View all trips') {
      goTo(d.trips.isEmpty ? 'tripsempty' : 'trips');
      return;
    }
    if (destination != null) {
      goTo(destination);
      return;
    }
    final map = <String, String>{
      'Account and Plus': 'profile',
      'Search campsites': 'loading',
      'Show campsites': guest ? 'guest' : 'explore',
      'Plan this trip': 'dates',
      'Change dates': 'dates',
      'Choose a valid range': 'dates',
      'Try past dates': 'dateerror',
      'Try reversed range': 'checkout-must-follow-arrival',
      'Try unavailable dates': 'those-dates-are-unavailable',
      'Cancel date change': d.editingTrip ? tripRoute : reviewRoute,
      'Return to review': reviewRoute,
      'View trip': tripRoute,
      'View updated trip': tripRoute,
      'View current trip': tripRoute,
      'Keep trip': tripRoute,
      'Return to trip': tripRoute,
      'Return to owner': tripRoute,
      'Back to my trip': tripRoute,
      'View affected trip': tripRoute,
      'Trip conditions': d.site == 'Sunset Ridge'
          ? 'unknown'
          : 'tripconditions',
      'Manage alerts': 'preferences',
      'All updates': 'alerts',
      'Done': route == 'profilesaved'
          ? (d.plus ? 'profileplus' : 'profileupdated')
          : 'alerts',
      'Enable trip updates': 'notifprompt',
      'Allow notifications': reviewRoute,
      'Not now': reviewRoute,
      'View saved campsites': d.saved ? 'saved' : 'savedempty',
      'Downloaded trips': d.downloads.isNotEmpty
          ? 'downloaded-summaries'
          : 'no-downloaded-trips',
      'Downloaded summaries': d.downloads.isNotEmpty
          ? 'downloaded-summaries'
          : 'no-downloaded-trips',
      'Offline summaries': d.downloads.isNotEmpty
          ? 'downloaded-summaries'
          : 'no-downloaded-trips',
      'All downloads': d.downloads.isNotEmpty
          ? 'downloaded-summaries'
          : 'no-downloaded-trips',
      'View saved summaries': d.downloads.isNotEmpty
          ? 'downloaded-summaries'
          : 'no-downloaded-trips',
      'Open downloaded trip': d.downloads.isNotEmpty
          ? 'downloaded'
          : 'no-downloaded-trips',
      'Open downloaded summary': 'downloaded',
      'Open recipient view': 'you-re-invited',
      'Ask owner to invite again': 'share',
      'View saved trips': d.trips.isEmpty ? 'tripsempty' : 'trips',
      'Profile': d.plus ? 'profileplus' : 'profile',
      'Back to Profile': d.plus ? 'profileplus' : 'profile',
      'Continue planning': 'explore',
      'Continue with free': 'profile',
      'Keep the free plan': 'profile',
      'Stay signed in': 'profile',
      'Redwood: fire restriction': 'alertdetail',
      'Sunset: conditions unconfirmed': 'unknown',
    };
    if (label == 'Cancel') {
      if (route == 'enter-a-display-name') {
        goTo('profile');
      } else {
        back();
      }
      return;
    }
    final target = map[label];
    if (target != null) {
      goTo(target);
      return;
    }
    notice('Demo selection saved: $label');
  }

  @override
  String display(String value) {
    if ([
      'dates',
      'choose-your-dates',
      'share',
      'shared',
      'linkcopied',
      'remove',
      'you-re-invited',
      'you-joined-the-trip',
      'downloaded',
      'save-for-offline-use',
      'ready-for-offline-use',
      'your-camping-group',
      'booking-response',
      'tripupdated',
      'updatedplan',
    ].contains(route)) {
      value = value.replaceAll('Redwood Grove', d.site);
    }
    if (value == 'On') {
      value =
          ((route == 'review' || route == 'ridgereview')
              ? d.bookingAlerts ?? d.alerts
              : d.alerts)
          ? 'On'
          : 'Off';
    }
    if (value == 'John') {
      value = d.name;
    }
    if (value.contains('Oct 23–25, 2026')) {
      final planning = [
        'dates',
        'choose-your-dates',
        'review',
        'ridgereview',
      ].contains(route);
      value = value.replaceAll(
        'Oct 23–25, 2026',
        planning ? draftDates ?? d.bookingDates ?? d.trip.dates : d.trip.dates,
      );
    }
    if (value.startsWith('Request pending')) {
      value = '${d.trip.status} · Demo';
    }
    return value;
  }

  @override
  String noticeValue(String name, String fallback) {
    switch (name) {
      case 'Notice / Name':
        return d.name;
      case 'Notice / Email':
        return d.email;
      case 'Notice / People':
        return d.trip.invitation;
      case 'Notice / Downloaded dates':
        return d.trip.downloadedDates.isEmpty
            ? 'No offline copy saved'
            : d.trip.downloadedDates;
      case 'Notice / Booking status':
        return '${d.trip.status} · Demo';
      default:
        return display(fallback);
    }
  }

  @override
  Widget input(String label, String hint, String initial) {
    fields.putIfAbsent(label, () => initial);
    return TextFormField(
      key: ValueKey(label),
      initialValue: fields[label],
      obscureText: label == 'Password',
      keyboardType: label.toLowerCase().contains('email')
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (v) => fields[label] = v,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Enter $label';
        }
        if (label.toLowerCase().contains('email') &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
          return 'Enter a valid email';
        }
        if (label == 'Password' && v.length < 8) {
          return 'Use at least 8 characters';
        }
        return null;
      },
    );
  }

  @override
  Widget filter(String key) {
    final choices = <String, List<String>>{
      'Site type': ['Tent', 'RV'],
      'Travelers': ['2 travelers', '4 travelers'],
      'Nightly budget': ['Any budget', 'Under \$55', 'Under \$70'],
      'Pet policy': ['Pet friendly', 'Any policy'],
    }[key]!;
    final selected = {
      'Site type': d.siteType,
      'Travelers': d.travelers,
      'Nightly budget': d.budget,
      'Pet policy': d.pets,
    }[key]!;
    return DropdownButtonFormField<String>(
      initialValue: selected,
      key: ValueKey('$key:$selected'),
      decoration: InputDecoration(labelText: key),
      items: choices
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) => setState(() {
        switch (key) {
          case 'Site type':
            d.siteType = v!;
          case 'Travelers':
            d.travelers = v!;
          case 'Nightly budget':
            d.budget = v!;
          case 'Pet policy':
            d.pets = v!;
        }
      }),
    );
  }

  @override
  Widget brandMark(String asset, Widget caption) {
    final splash = route.startsWith('splash');
    final inset = splash ? 50.0 : 28.0;
    final logoWidth = splash ? 84.0 : 53.0;
    final logo = Image.asset(asset, width: logoWidth);
    final controller = splashAnimation;
    return Container(
      height: splash ? 246 : 160,
      padding: EdgeInsets.symmetric(horizontal: inset),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: splash ? 110 : 68,
            child: Center(
              child: controller == null
                  ? logo
                  : ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.7,
                        end: 1,
                      ).animate(controller),
                      child: logo,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: caption),
        ],
      ),
    );
  }

  @override
  Widget alertSwitch(String label) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(label),
      subtitle: const Text('Sample condition updates'),
      value: route == 'preferences'
          ? draftAlerts ?? d.alerts
          : d.bookingAlerts ?? d.alerts,
      onChanged: (v) => setState(() {
        if (route == 'preferences') {
          draftAlerts = v;
        } else {
          d.bookingAlerts = v;
        }
      }),
    );
  }

  @override
  bool get hasRedwoodAlert => d.trips.contains('Redwood Grove');

  @override
  Widget areaMap() => CampsiteMap(
    onRedwood: () {
      d.site = 'Redwood Grove';
      goTo('detail');
    },
    onSunset: () {
      d.site = 'Sunset Ridge';
      goTo('ridge');
    },
  );

  void tab(int index) {
    if (!d.signedIn) {
      if (index == 0) {
        context.goNamed('guest');
        return;
      }
      goTo('authgate');
      return;
    }
    final routes = [
      'explore',
      d.trips.isEmpty ? 'tripsempty' : 'trips',
      d.saved ? 'saved' : 'savedempty',
      d.trips.isEmpty || !d.alerts ? 'alertsempty' : 'alerts',
      d.plus ? 'profileplus' : 'profile',
    ];
    context.goNamed(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final tabRoutes = [
      'explore',
      'guest',
      'map',
      'trips',
      'tripsempty',
      'saved',
      'savedempty',
      'alerts',
      'alertsempty',
      'profile',
      'profileplus',
      'profileupdated',
    ];
    final showTabs = widget.screen.tabs || tabRoutes.contains(route);
    final selected = route.contains('saved')
        ? 2
        : route.startsWith('trip')
        ? 1
        : route.startsWith('alert')
        ? 3
        : route.startsWith('profile')
        ? 4
        : 0;
    return Scaffold(
      bottomNavigationBar: showTabs
          ? NavigationBar(
              height: 78,
              backgroundColor: Colors.white,
              indicatorColor: softGreen,
              selectedIndex: selected,
              onDestinationSelected: tab,
              destinations: [
                for (final entry in [
                  'Explore',
                  'Trips',
                  'Saved',
                  'Alerts',
                  'Profile',
                ].asMap().entries)
                  NavigationDestination(
                    icon: Image.asset(
                      widget.screen.tabAssets[entry.key],
                      width: 18,
                      height: 18,
                    ),
                    label: entry.value,
                  ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    if (kIsWeb)
                      const Text('9:41', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    InkWell(
                      onTap: () => goTo('guide'),
                      child: const Text(
                        'Demo · Guide',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                    const Spacer(),
                    if (kIsWeb && widget.screen.statusAsset != null)
                      Image.asset(
                        widget.screen.statusAsset!,
                        width: 58,
                        height: 18,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final heading in widget.screen.header(this))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: heading,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  children: [
                    if (route == 'loading')
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (route == 'alerts' && d.trips.contains('Sunset Ridge'))
                      ListTile(
                        title: const Text('Sunset: conditions unconfirmed'),
                        onTap: () {
                          d.site = 'Sunset Ridge';
                          goTo('unknown');
                        },
                      ),
                    if (route == 'trips')
                      for (final site in d.trips)
                        Card(
                          child: ListTile(
                            title: Text(site),
                            subtitle: Text(
                              d.details[site]?.dates ?? d.trip.dates,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              d.site = site;
                              goTo(tripRoute);
                            },
                          ),
                        ),
                    for (final section in widget.screen.body(this))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: section,
                      ),
                    if (route == 'downloaded-summaries')
                      for (final site in d.downloads)
                        FilledButton(
                          onPressed: () {
                            d.site = site;
                            goTo(
                              d.trip.downloadedDates == d.trip.dates
                                  ? 'downloaded'
                                  : 'your-offline-copy-is-older',
                            );
                          },
                          child: Text(
                            '$site · ${d.details[site]!.downloadedDates}',
                          ),
                        ),
                    if (route == 'guide')
                      ExpansionTile(
                        title: const Text('All prototype screens'),
                        children: [
                          for (final screen in campPages)
                            ListTile(
                              title: Text(
                                screen.name.replaceAll(' · Complete flow', ''),
                              ),
                              onTap: () => context.pushNamed(screen.route),
                            ),
                        ],
                      ),
                    if (route == 'booking-response')
                      Text('Demo booking status: ${d.trip.status}'),
                  ],
                ),
              ),
            ),
            if (route == 'detail' || route == 'guestdetail')
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Row(
                  children: [
                    const Text(r'$65 / night'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => act('Check availability'),
                        child: const Text('Check availability'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
