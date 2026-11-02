import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

typedef Json = Map<String, dynamic>;

/// Session-only sample state. No account, booking, email or charge is sent.
class TripDetails {
  String dates = 'Oct 30–Nov 1, 2026', status = 'Request pending';
  String invitation = 'No invitations yet', downloadedDates = '';
}

class DemoState {
  bool signedIn = false, saved = false, plus = false, alerts = true;
  bool editingTrip = false;
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
    required this.screens,
    this.initialRoute = '/splash',
    this.initialState,
  });
  final List<Json> screens;
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
      for (final s in widget.screens)
        GoRoute(
          path: '/${s['route']}',
          name: s['route'] as String,
          builder: (_, _) => DesignScreen(
            key: ValueKey(s['id']),
            screen: s,
            screens: widget.screens,
            demo: demo,
          ),
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
  const DesignScreen({
    super.key,
    required this.screen,
    required this.screens,
    required this.demo,
  });
  final Json screen;
  final List<Json> screens;
  final DemoState demo;
  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

class _DesignScreenState extends State<DesignScreen> {
  final fields = <String, String>{};
  final form = GlobalKey<FormState>();
  Timer? timer;
  String? draftDates;
  bool? draftAlerts;
  bool get ridgeMatch => d.siteType == 'RV' && d.pets == 'Any policy';
  String get route => widget.screen['route'] as String;
  DemoState get d => widget.demo;
  String get tripId => d.site == 'Sunset Ridge' ? '4:3630' : '4:4229';
  String get reviewId => d.site == 'Sunset Ridge' ? '4:3577' : '4:4012';
  @override
  void initState() {
    super.initState();
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
    timer?.cancel();
    super.dispose();
  }

  void goId(String id) {
    final target = widget.screens.firstWhere((s) => s['id'] == id);
    context.pushNamed(target['route'] as String);
  }

  void back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('explore');
    }
  }

  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  bool get guest =>
      !d.signedIn &&
      [
        'guest',
        'guestdetail',
        'searchguest',
        'conditions',
        'weather',
        'fire',
        'closures',
      ].contains(route);

  void act(Json b) {
    final label = (b['name'] as String).replaceFirst('Action / ', '');
    final targets = (b['to'] as List? ?? []).cast<String>();
    if (label == '‹ Back' || label == 'Back') {
      back();
      return;
    }
    if (label == 'Sign in' || label == 'Create account') {
      if (route == 'welcome' || route == 'authgate') {
        goId(label == 'Sign in' ? '4:2505' : '4:2643');
        return;
      }
      if (!(form.currentState?.validate() ?? true)) {
        return;
      }
      d.signedIn = true;
      d.name = fields['Your name'] ?? d.name;
      d.email = fields['Email'] ?? d.email;
      goId('4:2859');
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
        goId('4:5130');
      }
      if (label == 'Send reset link') {
        goId('4:2832');
      }
      if (label == 'Send invitation') {
        d.trip.invitation =
            'Invitation pending · ${fields['Invitation email'] ?? 'friend@example.com'}';
        goId('4:4530');
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
      goId('4:3022');
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
        goId('4:2924');
      } else {
        d.saved = true;
        goId('4:3516');
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
        goId('4:2924');
      } else {
        d.editingTrip = false;
        goId('4:3875');
      }
      return;
    }
    if (label == 'Trip Conditions' || label == 'View conditions') {
      goId(d.site == 'Sunset Ridge' ? '4:3822' : '4:3684');
      return;
    }
    if (label == 'Enable trip updates' && guest) {
      goId('4:2924');
      return;
    }
    if (label == 'Edit dates') {
      d.editingTrip = true;
      goId('4:3875');
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
      d.trip.dates = draftDates ?? d.trip.dates;
      goId(d.editingTrip ? '4:4359' : reviewId);
      return;
    }
    if (label == 'Condition-change alerts' ||
        label == 'Condition-change notifications') {
      setState(() => d.alerts = !d.alerts);
      return;
    }
    if (label == 'Request to book · Demo' || label == 'Retry request') {
      if (d.trips.isNotEmpty && !d.trips.contains(d.site) && !d.plus) {
        goId('4:5225');
        return;
      }
      d.trips.add(d.site);
      d.trip.status = 'Request pending';
      goId(d.site == 'Sunset Ridge' ? '4:3604' : '4:4152');
      return;
    }
    if (label == 'Remove trip' && route == 'remove') {
      d.trips.remove(d.site);
      d.details.remove(d.site);
      goId(d.trips.isEmpty ? '4:4603' : '4:4179');
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
    if (label == 'Copy demo trip link') {
      Clipboard.setData(
        const ClipboardData(text: 'campready://invitation/demo'),
      );
      goId('4:4553');
      return;
    }
    if (label == 'Accept invitation') {
      d.trip.invitation = 'Friend joined';
      goId('60:1353');
      return;
    }
    if (label == 'Decline invitation') {
      d.trip.invitation = 'Invitation declined';
      goId('60:1381');
      return;
    }
    if (label == 'Revoke invitation') {
      d.trip.invitation = 'Invitation revoked';
      goId('60:1409');
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
      goId(d.plus ? '60:1493' : '4:5225');
      return;
    }
    if (label == 'Complete download') {
      d.trip.downloadedDates = d.trip.dates;
    }
    if (label == 'Delete downloaded copy') {
      d.trip.downloadedDates = '';
      goId(d.downloads.isEmpty ? '60:1577' : '60:1465');
      return;
    }
    if (label == 'Show matching campsites') {
      goId(
        !(ridgeMatch || d.siteType == 'Tent' && d.travelers == '2 travelers') ||
                d.budget == 'Under \$55'
            ? '60:1689'
            : '60:1661',
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
      if (targets.isNotEmpty) goId(targets.first);
      return;
    }
    if (label == 'Santa Cruz' || label == 'Boulder Creek') {
      fields['Destination'] = label;
      notice('Destination: $label');
      return;
    }
    if ((label == 'Redwood Grove' || label == 'Sunset Ridge') &&
        route == 'trips') {
      d.site = label;
      goId(tripId);
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
      d.trips.add(d.site);
    }
    if (label == 'Open downloaded trip' && d.downloads.isNotEmpty) {
      if (!d.downloads.contains(d.site)) d.site = d.downloads.first;
      goId(d.trip.downloadedDates == d.trip.dates ? '4:5521' : '60:1605');
      return;
    }
    if (label == 'Save preferences') d.alerts = draftAlerts ?? d.alerts;
    if (label == 'Redwood: fire restriction') d.site = 'Redwood Grove';
    if (label == 'Sunset: conditions unconfirmed') d.site = 'Sunset Ridge';
    if (label == 'View affected trip') d.site = 'Redwood Grove';
    if (label == 'View trips' ||
        label == 'Your trips' ||
        label == 'View all trips') {
      goId(d.trips.isEmpty ? '4:4603' : '4:4179');
      return;
    }
    if (targets.isNotEmpty) {
      goId(targets.first);
      return;
    }
    final map = <String, String>{
      'Account and Plus': '4:4988',
      'Search campsites': '4:5548',
      'Show campsites': guest ? '4:3022' : '4:2956',
      'Plan this trip': '4:3875',
      'Change dates': '4:3875',
      'Choose a valid range': '4:3875',
      'Try past dates': '4:3986',
      'Try reversed range': '60:1185',
      'Try unavailable dates': '60:1213',
      'Cancel date change': d.editingTrip ? tripId : reviewId,
      'Return to review': reviewId,
      'View trip': tripId,
      'View updated trip': tripId,
      'View current trip': tripId,
      'Keep trip': tripId,
      'Return to trip': tripId,
      'Return to owner': tripId,
      'Back to my trip': tripId,
      'View affected trip': tripId,
      'Trip conditions': d.site == 'Sunset Ridge' ? '4:3822' : '4:4289',
      'Manage alerts': '4:4826',
      'All updates': '4:4755',
      'Done': route == 'profilesaved'
          ? (d.plus ? '4:5371' : '4:5149')
          : '4:4755',
      'Enable trip updates': '4:4126',
      'Allow notifications': reviewId,
      'Not now': reviewId,
      'View saved campsites': d.saved ? '4:4653' : '4:4705',
      'Downloaded trips': d.downloads.isNotEmpty ? '60:1465' : '60:1577',
      'Downloaded summaries': d.downloads.isNotEmpty ? '60:1465' : '60:1577',
      'Offline summaries': d.downloads.isNotEmpty ? '60:1465' : '60:1577',
      'All downloads': d.downloads.isNotEmpty ? '60:1465' : '60:1577',
      'View saved summaries': d.downloads.isNotEmpty ? '60:1465' : '60:1577',
      'Open downloaded trip': d.downloads.isNotEmpty ? '4:5521' : '60:1577',
      'Open downloaded summary': '4:5521',
      'Open recipient view': '60:1325',
      'Ask owner to invite again': '4:4444',
      'View saved trips': d.trips.isEmpty ? '4:4603' : '4:4179',
      'Profile': d.plus ? '4:5371' : '4:4988',
      'Back to Profile': d.plus ? '4:5371' : '4:4988',
      'Continue planning': '4:2956',
      'Continue with free': '4:4988',
      'Keep the free plan': '4:4988',
      'Stay signed in': '4:4988',
      'Redwood: fire restriction': '4:4799',
      'Sunset: conditions unconfirmed': '4:3822',
    };
    if (label == 'Cancel') {
      if (route == 'enter-a-display-name') {
        goId('4:4988');
      } else {
        back();
      }
      return;
    }
    final target = map[label];
    if (target != null) {
      goId(target);
      return;
    }
    notice('Demo selection saved: $label');
  }

  Color color(dynamic c, [Color fallback = ink]) => c is Map
      ? Color.fromRGBO(
          ((c['r'] as num) * 255).round(),
          ((c['g'] as num) * 255).round(),
          ((c['b'] as num) * 255).round(),
          1,
        )
      : fallback;
  List<Json> texts(Json b) => (b['texts'] as List? ?? []).cast<Json>();
  String textValue(Json t) => t['text'] as String;
  Widget text(Json t) {
    var value = textValue(t);
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
      value = d.alerts ? 'On' : 'Off';
    }
    if (value == 'John') {
      value = d.name;
    }
    if (t['literal'] != true && value.contains('Oct 23–25, 2026')) {
      value = value.replaceAll('Oct 23–25, 2026', draftDates ?? d.trip.dates);
    }
    if (value.startsWith('Request pending')) {
      value = '${d.trip.status} · Demo';
    }
    final size = (t['size'] as num? ?? 14).toDouble();
    return Text(
      value,
      style: TextStyle(
        fontSize: size,
        height:
            (size >= 26
                ? 32
                : size >= 20
                ? 26
                : size == 12
                ? 16
                : 20) /
            size,
        fontWeight: t['weight'] == 'Bold'
            ? FontWeight.w700
            : t['weight'] == 'Medium'
            ? FontWeight.w500
            : FontWeight.w400,
        color: color(t['color']),
      ),
    );
  }

  Widget textStack(List<Json> items, {double gap = 6}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        text(items[i]),
      ],
    ],
  );
  Map<String, dynamic> get assets =>
      (widget.screen['assets'] as Map? ?? {}).cast<String, dynamic>();
  Widget photo(double height) {
    final key = assets.keys
        .where((k) => k.toLowerCase().contains('photo'))
        .firstOrNull;
    final path = key == null ? null : assets[key] as String;
    return path == null
        ? const SizedBox.shrink()
        : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              path,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: d.site,
            ),
          );
  }

  Widget field(Json b) {
    final ts = texts(b);
    final label = b['name'] == 'Action / Display name'
        ? 'Display name'
        : b['name'] == 'Action / Invitation email'
        ? 'Invitation email'
        : ts.length > 1
        ? textValue(ts.last)
        : b['name'].toString().split('/ ').last;
    final sample = b['name'].toString().startsWith('Sample value');
    final initial = sample
        ? textValue(ts.first).replaceAll('••••••••••', 'campready123')
        : '';
    fields.putIfAbsent(label, () => initial);
    return TextFormField(
      key: ValueKey(b['id']),
      initialValue: fields[label],
      obscureText: label == 'Password',
      keyboardType: label.toLowerCase().contains('email')
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: ts.isEmpty ? '' : textValue(ts.first),
      ),
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

  Widget block(Json b) {
    final name = b['name'] as String;
    final ts = texts(b);
    if (route == 'matching-campsites' &&
        ridgeMatch &&
        name == 'Action / Redwood Grove') {
      return ListTile(
        title: const Text('Sunset Ridge'),
        subtitle: const Text('RV · Up to 4 · From \$55/night'),
        onTap: () {
          d.site = 'Sunset Ridge';
          goId('4:3549');
        },
      );
    }
    if (name == 'Options') {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => goId('4:3147'),
              child: const Text('Filters'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => goId('4:3393'),
              child: const Text('Map view'),
            ),
          ),
        ],
      );
    }
    if (name.contains('Input ') ||
        name.startsWith('Sample value') ||
        name == 'Action / Display name' ||
        name == 'Action / Invitation email') {
      return field(b);
    }
    if (route == 'filters' &&
        [
          'Action / Site type',
          'Action / Travelers',
          'Action / Nightly budget',
          'Action / Pet policy',
        ].contains(name)) {
      final key = name.split('/ ').last;
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
    if (name.startsWith('Photo')) {
      return photo((b['h'] as num).toDouble());
    }
    if (name == 'CampReady mark') {
      return Container(
        height: 246,
        decoration: BoxDecoration(
          color: softGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: SvgPicture.asset(
                assets['imgGroup2'] as String,
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 16),
            textStack(ts),
          ],
        ),
      );
    }
    if (name == 'Illustrative area map') {
      return areaMap();
    }
    if (name == 'Unused map fallback') {
      final key = assets.keys
          .where((k) => k.toLowerCase().contains('map'))
          .firstOrNull;
      return key == null
          ? Container(
              height: 250,
              color: softGreen,
              child: const Center(child: Text('Illustrative map · Santa Cruz')),
            )
          : media(assets[key] as String, 250);
    }
    if (name == 'Action / Condition-change alerts' ||
        name == 'Action / Condition-change notifications') {
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(textValue(ts.first)),
        subtitle: const Text('Sample condition updates'),
        value: route == 'preferences' ? draftAlerts ?? d.alerts : d.alerts,
        onChanged: (v) => setState(() {
          if (route == 'preferences') {
            draftAlerts = v;
          } else {
            d.alerts = v;
          }
        }),
      );
    }
    if (name == 'Three-day forecast') {
      return Row(
        children: [
          for (var i = 0; i < ts.length; i += 4)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: textStack(ts.sublist(i, (i + 4).clamp(0, ts.length))),
              ),
            ),
        ],
      );
    }
    if (name == 'Action / Campsite card') {
      return InkWell(
        onTap: () => act(b),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: outline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              photo(142),
              Padding(padding: const EdgeInsets.all(16), child: textStack(ts)),
            ],
          ),
        ),
      );
    }
    if (name == 'Trip Conditions card') {
      return InkWell(onTap: () => goId('4:3684'), child: card(b, ts));
    }
    if (b['type'] == 'TEXT') {
      return textStack(ts);
    }
    if (name.startsWith('Action') && ts.length == 1) {
      return FilledButton(
        key: ValueKey(b['id']),
        onPressed: () => act(b),
        child: Text(textValue(ts.first), textAlign: TextAlign.center),
      );
    }
    if (name.startsWith('Action')) {
      return InkWell(
        key: ValueKey(b['id']),
        onTap: () => act(b),
        borderRadius: BorderRadius.circular(12),
        child: card(b, ts),
      );
    }
    return card(b, ts);
  }

  Widget areaMap() => AspectRatio(
    aspectRatio: 342 / 230,
    child: LayoutBuilder(
      builder: (context, box) {
        final layers = <(String, double, double, double, double)>[
          ('imgIllustrativeAreaMap', 0, 0, 342, 230),
          ('imgVector', 0, 153.09, 105, 76.91),
          ('imgIllustrativeAreaMap1', -2.02, -5.87, 348.5, 238.23),
          ('imgIllustrativeAreaMap2', 0, -.78, 342.58, 231.1),
          ('imgVector1', 122.98, 81.99, 28, 28),
          ('imgVector1', 241.01, 33.99, 28, 28),
          ('imgVector2', 132.01, 91.01, 10, 10),
          ('imgVector2', 250, 43.01, 10, 10),
        ];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              for (final layer in layers)
                if (assets[layer.$1] != null)
                  Positioned(
                    left: layer.$2 * box.maxWidth / 342,
                    top: layer.$3 * box.maxWidth / 342,
                    width: layer.$4 * box.maxWidth / 342,
                    height: layer.$5 * box.maxWidth / 342,
                    child: SvgPicture.asset(
                      assets[layer.$1] as String,
                      fit: BoxFit.fill,
                    ),
                  ),
              Positioned(
                left: 113 * box.maxWidth / 342,
                top: 72 * box.maxWidth / 342,
                width: 48,
                height: 48,
                child: Semantics(
                  label: 'Redwood Grove map pin',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      d.site = 'Redwood Grove';
                      goId('4:3454');
                    },
                  ),
                ),
              ),
              Positioned(
                left: 231 * box.maxWidth / 342,
                top: 24 * box.maxWidth / 342,
                width: 48,
                height: 48,
                child: Semantics(
                  label: 'Sunset Ridge map pin',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      d.site = 'Sunset Ridge';
                      goId('4:3549');
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget media(String path, double height) => path.endsWith('.svg')
      ? SvgPicture.asset(path, height: height)
      : Image.asset(path, height: height, fit: BoxFit.cover);
  Widget card(Json b, List<Json> ts) {
    var items = ts;
    final name = b['name'] as String;
    String? replacement;
    if (name == 'Notice / Name') {
      replacement = d.name;
    }
    if (name == 'Notice / Email') {
      replacement = d.email;
    }
    if (name == 'Notice / People') {
      replacement = d.trip.invitation;
    }
    if (name == 'Notice / Downloaded dates') {
      replacement = d.trip.downloadedDates.isEmpty
          ? 'No offline copy saved'
          : d.trip.downloadedDates;
    }
    if (name == 'Notice / Booking status') {
      replacement = '${d.trip.status} · Demo';
    }
    if (replacement != null && ts.length > 1) {
      items = [
        ts.first,
        {...ts[1], 'text': replacement, 'literal': true},
      ];
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color(b['bg'], Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline),
        boxShadow: name.startsWith('Action')
            ? [
                const BoxShadow(
                  color: Color(0x17263329),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b['name'] == 'Action / Trip Conditions' &&
              assets['imgIconSun'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SvgPicture.asset(
                assets['imgIconSun'] as String,
                width: 24,
                height: 24,
              ),
            ),
          textStack(items),
        ],
      ),
    );
  }

  void tab(int index) {
    if (!d.signedIn) {
      if (index == 0) {
        context.goNamed('guest');
        return;
      }
      goId('4:2924');
      return;
    }
    final ids = [
      '4:2956',
      d.trips.isEmpty ? '4:4603' : '4:4179',
      d.saved ? '4:4653' : '4:4705',
      d.trips.isEmpty ? '4:4937' : '4:4755',
      d.plus ? '4:5371' : '4:4988',
    ];
    final target = widget.screens.firstWhere((s) => s['id'] == ids[index]);
    context.goNamed(target['route'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final header = (widget.screen['header'] as List).cast<Json>();
    final blocks = [
      ...(widget.screen['blocks'] as List).cast<Json>(),
      ...(widget.screen['extras'] as List? ?? []).cast<Json>(),
    ];
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
    final showTabs = widget.screen['tabs'] == true || tabRoutes.contains(route);
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
                NavigationDestination(
                  icon: SvgPicture.asset(
                    assets['imgGroup'] as String,
                    height: 18,
                    width: 18,
                  ),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    assets['imgGroup2'] as String,
                    height: 18,
                    width: 18,
                  ),
                  label: 'Trips',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    assets['imgGroup1'] as String,
                    height: 18,
                    width: 18,
                  ),
                  label: 'Saved',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    assets['imgGroup3'] as String,
                    height: 18,
                    width: 18,
                  ),
                  label: 'Alerts',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    assets['imgGroup4'] as String,
                    height: 18,
                    width: 18,
                  ),
                  label: 'Profile',
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
                    const Text('9:41', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    InkWell(
                      onTap: () => goId('4:2379'),
                      child: const Text(
                        'Demo · Guide',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                    const Spacer(),
                    if (assets['imgAndroidStatusIcons'] != null)
                      SvgPicture.asset(
                        assets['imgAndroidStatusIcons'] as String,
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
                    for (final b in header)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child:
                            b['name'] == 'Back' ||
                                b['name'].toString().contains('‹ Back')
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: back,
                                  child: const Text('‹ Back'),
                                ),
                              )
                            : textStack(texts(b)),
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
                          goId('4:3822');
                        },
                      ),
                    for (final b in blocks)
                      if (!(route == 'alerts' &&
                          b['name'] == 'Action / Redwood: fire restriction' &&
                          !d.trips.contains('Redwood Grove')))
                        if (!(route == 'trips' &&
                            [
                              'Action / Redwood Grove',
                              'Action / Sunset Ridge',
                            ].contains(b['name'])))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: block(b),
                          ),
                    if (route == 'downloaded-summaries')
                      for (final site in d.downloads)
                        FilledButton(
                          onPressed: () {
                            d.site = site;
                            goId(
                              d.trip.downloadedDates == d.trip.dates
                                  ? '4:5521'
                                  : '60:1605',
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
                          for (final screen in widget.screens)
                            ListTile(
                              title: Text(
                                screen['name'].toString().replaceAll(
                                  ' · Complete flow',
                                  '',
                                ),
                              ),
                              onTap: () =>
                                  context.pushNamed(screen['route'] as String),
                            ),
                        ],
                      ),
                    if (route == 'booking-response')
                      Text('Demo booking status: ${d.trip.status}'),
                    if (route == 'trips')
                      for (final site in d.trips)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FilledButton(
                            onPressed: () {
                              d.site = site;
                              goId(tripId);
                            },
                            child: Text(site),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
