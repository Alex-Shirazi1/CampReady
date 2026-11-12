import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/booking/booking_cubit.dart';
import '../blocs/explore/explore_cubit.dart';
import '../blocs/notifications/notifications_bloc.dart';
import '../blocs/profile/profile_cubit.dart';
import '../blocs/saved/saved_cubit.dart';
import '../blocs/trips/trips_cubit.dart';
import '../campsite_map.dart';
import '../models/campsite.dart';
import '../models/stay.dart';
import '../repositories/auth_repository.dart';
import '../repositories/campsite_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/photo_repository.dart';
import '../repositories/trip_repository.dart';
import '../repositories/weather_repository.dart';
import '../router.dart';
import '../screens.dart';
import '../services/services.dart';
import '../theme.dart';
import 'splash_view.dart';

/// Renders one [CampPage] and connects its buttons to the blocs.
class DesignScreen extends StatefulWidget {
  const DesignScreen({
    super.key,
    required this.screen,
    this.siteId,
    this.tripId,
    this.extra,
    this.from,
  });

  final CampPage screen;
  final String? siteId;
  final String? tripId;
  final Object? extra;

  /// Where to return after signing in.
  final String? from;

  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

const _tabRoots = {
  'explore',
  'guest',
  'trips',
  'tripsempty',
  'saved',
  'savedempty',
  'alerts',
  'alertsempty',
  'profile',
  'profileplus',
  'profileupdated',
  'welcome',
};

class _DesignScreenState extends State<DesignScreen> implements PageControls {
  final fields = <String, String>{};
  final form = GlobalKey<FormState>();
  bool busy = false;
  bool? draftAlerts;
  Timer? timer;
  Future<Forecast>? _forecast;

  String get route => widget.screen.route;
  AppUser? get user => context.read<AuthBloc>().state.user;
  bool get guest => user == null;
  TripsCubit get _trips => context.read<TripsCubit>();
  BookingCubit get _booking => context.read<BookingCubit>();
  ProfileCubit get _profile => context.read<ProfileCubit>();
  ExploreCubit get _explore => context.read<ExploreCubit>();
  CampsiteRepository get _sites => context.read<CampsiteRepository>();

  @override
  void initState() {
    super.initState();
    if (route == 'loading') {
      timer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) _goRoot(guest ? 'guest' : 'explore');
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ---- data for the screens ----

  @override
  TripView? get trip {
    final state = _trips.state;
    if (widget.tripId != null) return state.byId(widget.tripId);
    final site = _sites.byId(widget.siteId);
    return site == null ? null : state.ownedFor(site.name);
  }

  @override
  Campsite get campsite {
    final record = widget.tripId == null
        ? null
        : _trips.state.byId(widget.tripId)?.record;
    return _sites.byId(widget.siteId) ??
        _sites.byId(record?.siteId) ??
        _sites.byId(record?.site) ??
        _sites.all.first;
  }

  @override
  String get tripDates {
    final record = trip?.record;
    if (record != null) return record.dates;
    return draftDates;
  }

  @override
  String get draftDates => _booking.state.stay?.label ?? 'No dates selected';

  @override
  String? get bookingError => _booking.state.error;

  @override
  String get bookingTotal {
    final stay = _booking.state.stay;
    if (stay == null) return 'Choose dates to see the total';
    final price = campsite.pricePerNight;
    return '${stay.nightsLabel} × \$$price = \$${stay.nights * price} · Simulated, no charge';
  }

  @override
  bool get alertsOn => _profile.state.alertsEnabled;

  @override
  String get userName {
    final name = user?.displayName ?? '';
    return name.isEmpty ? (guest ? 'Not signed in' : 'Add your name') : name;
  }

  @override
  String get userEmail => user?.email ?? 'Not signed in';

  @override
  String get resetEmail =>
      widget.extra is String ? widget.extra as String : 'that email';

  @override
  bool get plus => _profile.state.plus;

  @override
  String get destination => _explore.state.query;

  @override
  List<Campsite> get results => _explore.state.results;

  @override
  List<Campsite> get savedSites => [
    for (final site in _sites.all)
      if (context.read<SavedCubit>().state.contains(site.id)) site,
  ];

  @override
  List<Campsite> get matches => _explore.matches;

  @override
  List<TripView> get trips => _trips.state.trips;

  @override
  List<TripView> get downloads => _trips.state.downloads.toList();

  @override
  List<AppNotification> get notifications =>
      context.read<NotificationsBloc>().state.items;

  @override
  AppNotification? get selectedNotification =>
      widget.extra is AppNotification ? widget.extra as AppNotification : null;

  @override
  String? distanceLabel(Campsite site) => _explore.state.distanceLabel(site.id);

  @override
  bool get nearMe => _explore.state.nearMe;

  @override
  String get locationMessage => switch (_explore.state.location) {
    LocationStatus.deniedForever => 'Location is blocked for CampReady. Turn it on in Settings, or search instead.',
    LocationStatus.serviceDisabled => 'Location services are off on this device. Turn them on, or search instead.',
    LocationStatus.unavailable =>
      'We couldn’t get your location. Try again or search instead.',
    _ => 'Location access is off. You can still search by destination.',
  };

  @override
  String get shareLink =>
      'https://campready-group2.web.app/trips/${trip?.id ?? ''}';

  @override
  bool get showDemo => showDemoBuild;

  @override
  bool get localMode => !context.read<AuthRepository>().usesFirebase;

  // ---- navigation ----

  Map<String, String> _params(String target) {
    if (campsiteRoutes.contains(target)) return {'siteId': campsite.id};
    if (tripRoutes.contains(target)) {
      final id = widget.tripId ?? trip?.id;
      if (id != null) return {'tripId': id};
    }
    return const {};
  }

  String _resolve(String target) {
    target = routeAliases[target] ?? target;
    final s = _trips.state;
    return switch (target) {
      'trips' || 'tripsempty' => s.trips.isEmpty ? 'tripsempty' : 'trips',
      'saved' || 'savedempty' =>
        context.read<SavedCubit>().state.ids.isEmpty ? 'savedempty' : 'saved',
      'alerts' ||
      'alertsempty' => notifications.isEmpty ? 'alertsempty' : 'alerts',
      'profileplus' || 'profileupdated' => 'profile',
      'explore' || 'guest' => guest ? 'guest' : 'explore',
      _ => target,
    };
  }

  @override
  void goTo(String target, {Object? extra}) {
    if (!mounted) return;
    final name = _resolve(target);
    if (tripRoutes.contains(name) && _params(name).isEmpty) {
      _goRoot('trips');
      return;
    }
    if (_tabRoots.contains(name)) {
      context.goNamed(name, extra: extra);
    } else {
      context.pushNamed(name, pathParameters: _params(name), extra: extra);
    }
  }

  void _goRoot(String target) {
    if (!mounted) return;
    context.goNamed(_resolve(target));
  }

  void _goTrip(String tripId, [String name = 'trip']) {
    if (!mounted) return;
    context.goNamed(name, pathParameters: {'tripId': tripId});
  }

  void _goSite(String siteId, [String name = 'detail']) {
    if (!mounted) return;
    context.pushNamed(name, pathParameters: {'siteId': siteId});
  }

  @override
  void back() {
    if (context.canPop()) {
      context.pop();
    } else {
      _goRoot('explore');
    }
  }

  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // ---- actions ----

  @override
  void act(String label, [String? target]) {
    // Dialogs show their own UI, so they skip the busy indicator.
    if (label == 'Choose dates' || label == 'Choose a valid range') {
      unawaited(_pickDates());
      return;
    }
    unawaited(_run(() => _perform(label, target)));
  }

  Future<void> _run(Future<void> Function() task) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await task();
    } on PlanLimitException {
      goTo('premium');
    } on AuthException catch (e) {
      if (mounted) notice(e.message);
    } on StateError catch (e) {
      if (mounted) notice(e.message);
    } on TimeoutException {
      if (mounted) {
        notice(
          'The connection timed out. A queued change may still save when you reconnect. Refresh before trying again.',
        );
      }
    } catch (_) {
      if (mounted) {
        notice(
          'Could not complete this action. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool _valid() => form.currentState?.validate() ?? true;

  Future<void> _perform(String label, String? target) async {
    final me = user;
    final prefix = label.indexOf(': ');
    if (prefix > 0) {
      await _performFor(
        label.substring(0, prefix),
        label.substring(prefix + 2),
      );
      return;
    }

    switch (label) {
      case '‹ Back' || 'Back' || 'Cancel' when target == null:
        back();
        return;
      case 'Start full app':
        context.go('/splash');
        return;

      // Account
      case 'Sign in' || 'Create an account' || 'New to CampReady?'
          when !route.startsWith('signin') && !route.startsWith('signup'):
        final next = label == 'Sign in' ? 'signin' : 'signup';
        context.pushNamed(
          next,
          queryParameters: {if (widget.from != null) 'from': widget.from!},
        );
        return;
      case 'Sign in':
        if (!_valid()) return;
        context.read<AuthBloc>().add(
          AuthSignInRequested(
            email: fields['Email'] ?? '',
            password: fields['Password'] ?? '',
          ),
        );
        return;
      case 'Create account':
        if (!_valid()) return;
        context.read<AuthBloc>().add(
          AuthSignUpRequested(
            email: fields['Email'] ?? '',
            password: fields['Password'] ?? '',
            displayName: fields['Your name'],
          ),
        );
        return;
      case 'Send reset link':
        if (!_valid()) return;
        final email = (fields['Email'] ?? '').trim();
        await context.read<AuthRepository>().sendPasswordReset(email);
        if (mounted) context.pushNamed('resetsent', extra: email);
        return;
      case 'Get started' || 'Explore as a guest':
        _goRoot('guest');
        return;
      case 'Keep browsing':
        back();
        return;
      case 'Save profile':
        if (!_valid() || me == null) return;
        final auth = context.read<AuthBloc>();
        final next = auth.stream.firstWhere((s) => s is AuthAuthenticated);
        auth.add(AuthDisplayNameChanged(fields['Display name'] ?? ''));
        final state = await next.timeout(const Duration(seconds: 20));
        if (!mounted) return;
        if (state is AuthAuthenticated && state.message != null) {
          notice(state.message!);
          return;
        }
        goTo('profilesaved');
        return;
      case 'Confirm sign out':
        final auth = context.read<AuthBloc>();
        final out = auth.stream.firstWhere((s) => s is AuthUnauthenticated);
        auth.add(AuthSignOutRequested());
        await out.timeout(const Duration(seconds: 20));
        if (mounted) context.goNamed('welcome');
        return;
      case 'Refresh account':
        if (me != null) await _reload(me);
        return;

      // Location and search
      case 'Allow location' || 'Use my current location':
        await _locate();
        return;
      case 'Try location again':
        // Check again first: the user may have just turned it on.
        final status = await _explore.locate();
        if (!mounted) return;
        if (status == LocationStatus.granted) {
          _goRoot('explore');
          return;
        }
        final location = context.read<LocationRepository>();
        if (status == LocationStatus.deniedForever && !kIsWeb) {
          await location.openAppSettings();
        } else if (status == LocationStatus.serviceDisabled && !kIsWeb) {
          await location.openLocationSettings();
        }
        return;
      case 'Santa Cruz' || 'Boulder Creek':
        _explore.search(label);
        _goRoot('explore');
        return;
      case 'Show campsites' || 'Search campsites':
        _explore.search(fields['Destination'] ?? destination);
        _goRoot('explore');
        return;
      case 'Clear search':
        _explore.clearSearch();
        return;
      case 'Show matching campsites':
        goTo(matches.isEmpty ? 'no-matching-campsites' : 'matching-campsites');
        return;
      case 'Reset filters':
        _explore.resetFilters();
        if (target != null) goTo(target);
        return;

      // Campsite
      case 'Trip Conditions':
        goTo(campsite.conditionsKnown ? 'conditions' : 'unknown');
        return;
      case 'Back to campsite':
        context.goNamed('detail', pathParameters: {'siteId': campsite.id});
        return;
      case 'Save campsite':
        if (me == null) {
          _authGate();
          return;
        }
        await context.read<SavedCubit>().save(me.uid, campsite);
        goTo('detailsaved');
        return;
      case 'Remove from saved':
        if (me != null) {
          await context.read<SavedCubit>().remove(me.uid, campsite);
        }
        back();
        return;
      case 'Plan this trip' ||
          'Plan a trip here' ||
          'Check availability' ||
          'Plan with these conditions':
        if (me == null) {
          _authGate();
          return;
        }
        final existing = _trips.state.ownedFor(campsite.name);
        if (existing != null) {
          notice('You already have a trip here. Edit its dates from the trip.');
          _goTrip(existing.id);
          return;
        }
        _booking.start(campsite.id, alerts: alertsOn);
        goTo('dates');
        return;
      case 'Enable trip updates':
        if (me == null) {
          _authGate();
          return;
        }
        goTo('notifprompt');
        return;
      case 'Allow notifications':
        if (me == null) return;
        final warning = await _profile.saveAlerts(me.uid, true);
        if (!mounted) return;
        notice(warning ?? 'Trip updates are on.');
        back();
        return;
      case 'Not now':
        back();
        return;

      // Dates and booking
      case 'Use selected dates':
        await _useDates();
        return;
      case 'Change dates':
        goTo('dates');
        return;
      case 'Request to book':
        await _book();
        return;
      case 'View trip' || 'Return to trip' || 'Back to my trip':
        final current = trip;
        if (current == null) {
          _goRoot('trips');
        } else {
          _goTrip(current.id);
        }
        return;

      // Trips
      case 'All trips' ||
          'View trips' ||
          'View all trips' ||
          'Your trips' ||
          'Choose a trip' ||
          'Choose a trip to download':
        _goRoot('trips');
        return;
      case 'Trip conditions':
        goTo(campsite.conditionsKnown ? 'tripconditions' : 'unknown');
        return;
      case 'Edit dates':
        final current = trip;
        if (current == null) return;
        _booking.edit(
          siteId: campsite.id,
          tripId: current.id,
          stay: current.record.stay,
          alerts: alertsOn,
        );
        _goSite(campsite.id, 'dates');
        return;
      case 'Download summary':
        goTo(plus ? 'save-for-offline-use' : 'premium');
        return;
      case 'Confirm remove trip':
        final current = trip;
        if (current == null) return;
        await _trips.remove(current);
        _goRoot('trips');
        return;
      case 'Send invitation':
        await _share();
        return;
      case 'Copy trip link':
        await Clipboard.setData(ClipboardData(text: shareLink));
        goTo('linkcopied');
        return;
      case 'People on this trip':
        if (me != null) await _trips.load(me);
        if (route == 'your-camping-group') {
          if (mounted) notice('Group refreshed.');
        } else {
          goTo('your-camping-group');
        }
        return;
      case 'Revoke invitation':
        final current = trip;
        if (current == null) return;
        await _trips.revoke(current);
        if (mounted) {
          notice('Invitations revoked. They can no longer see this trip.');
        }
        return;
      case 'Accept invitation' || 'Decline invitation':
        final current = trip;
        if (current == null || me == null) return;
        final accept = label == 'Accept invitation';
        await _trips.respond(current, me, accept);
        if (!mounted) return;
        if (accept) {
          _goTrip(current.id, 'you-joined-the-trip');
        } else {
          context.goNamed('invitation-declined');
        }
        return;
      case 'Refresh shared plan':
        if (me != null) await _trips.load(me);
        if (mounted && trip != null) notice('Shared plan refreshed.');
        return;
      case 'Host accepts' ||
          'Host declines' ||
          'No response in 24 hours' ||
          'Request again':
        final current = trip;
        if (current == null) return;
        final status = switch (label) {
          'Host accepts' => 'Accepted',
          'Host declines' => 'Declined',
          'No response in 24 hours' => 'Expired',
          _ => 'Request pending',
        };
        final warning = await _trips.setStatus(
          current,
          status,
          notifyOwner: alertsOn,
        );
        _refreshNotifications();
        if (mounted) notice(warning ?? 'Booking status: $status');
        return;

      // Offline copies
      case 'Complete download':
        final current = trip;
        if (current == null) return;
        await _trips.setOfflineCopy(current, saved: true);
        goTo('ready-for-offline-use');
        return;
      case 'Refresh download':
        final current = trip;
        if (current == null) return;
        if (!plus) {
          goTo('premium');
          return;
        }
        await _trips.setOfflineCopy(current, saved: true);
        goTo('ready-for-offline-use');
        return;
      case 'Delete downloaded copy':
        final current = trip;
        if (current == null) return;
        await _trips.setOfflineCopy(current, saved: false);
        goTo(
          downloads.isEmpty ? 'no-downloaded-trips' : 'downloaded-summaries',
        );
        return;
      case 'Downloaded summaries' || 'Downloaded trips':
        goTo(
          downloads.isEmpty ? 'no-downloaded-trips' : 'downloaded-summaries',
        );
        return;
      case 'Open downloaded trip':
        _openDownload(downloads.isEmpty ? null : downloads.first);
        return;
      case 'Try connection again':
        if (me != null) {
          await _trips.load(me);
          if (_trips.state.status == TripsStatus.failure) {
            if (mounted) notice(_trips.state.error!);
            return;
          }
        }
        _goRoot('explore');
        return;

      // Alerts and preferences
      case 'Save preferences':
        if (me == null) return;
        final warning = await _profile.saveAlerts(
          me.uid,
          draftAlerts ?? alertsOn,
        );
        goTo('preferencessaved');
        if (warning != null && mounted) notice(warning);
        return;
      case 'View affected trip':
        final id = selectedNotification?.tripId;
        if (id != null) _goTrip(id);
        return;

      // Camera and photo library
      case 'Take photo' || 'Choose photo':
        if (me == null) return;
        final photo = await context.read<PhotoRepository>().pick(
          camera: label == 'Take photo',
        );
        if (photo == null) return;
        await _profile.setPhoto(me.uid, photo);
        if (mounted) notice('Profile photo saved.');
        return;

      // Plus (simulated)
      case 'Confirm upgrade':
        if (showDemo) {
          goTo('demo-payment-response');
          return;
        }
        if (me != null) await _profile.setPlus(me.uid, true);
        goTo('upgraded');
        return;
      case 'Upgrade succeeds':
        if (me != null) await _profile.setPlus(me.uid, true);
        goTo('upgraded');
        return;
      case 'Cancel membership':
        if (me != null) await _profile.setPlus(me.uid, false);
        goTo('pluscancelled');
        return;

      // Demo guide shortcuts
      case 'Explore and plan' ||
          'Trips and group sharing' ||
          'Account and Plus':
        if (me == null) {
          _authGate();
          return;
        }
        _goRoot(switch (label) {
          'Explore and plan' => 'explore',
          'Trips and group sharing' => 'trips',
          _ => 'profile',
        });
        return;
    }
    if (target != null) goTo(target);
  }

  Future<void> _performFor(String kind, String id) async {
    final me = user;
    switch (kind) {
      case 'Open campsite':
        _goSite(id);
      case 'Open trip':
        _goTrip(id);
      case 'Remove saved':
        final site = _sites.byId(id);
        if (me != null && site != null) {
          await context.read<SavedCubit>().remove(me.uid, site);
        }
        if (mounted && savedSites.isEmpty) _goRoot('savedempty');
      case 'Open update':
        await _openUpdate(id);
      case 'Open download':
        _openDownload(_trips.state.byId(id));
    }
  }

  void _authGate() => context.pushNamed(
    'authgate',
    queryParameters: {'from': GoRouterState.of(context).uri.toString()},
  );

  Future<void> _reload(AppUser me) async {
    await Future.wait([
      _trips.load(me),
      context.read<SavedCubit>().load(me.uid),
      _profile.load(me.uid),
    ]);
    _refreshNotifications();
  }

  void _refreshNotifications() {
    if (!mounted) return;
    context.read<NotificationsBloc>().add(
      NotificationsRefreshRequested(
        tripIds: {for (final t in _trips.state.trips) t.id},
      ),
    );
  }

  Future<void> _locate() async {
    final status = await _explore.locate();
    if (!mounted) return;
    if (status == LocationStatus.granted) {
      _goRoot('explore');
    } else if (route != 'denied') {
      goTo('denied');
    }
  }

  Future<void> _pickDates() async {
    final today = _booking.today;
    final current = _booking.state.stay;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: current == null || current.checkIn.isBefore(today)
          ? null
          : DateTimeRange(start: current.checkIn, end: current.checkOut),
      helpText: 'Choose your stay',
      saveText: 'Done',
    );
    if (picked == null) return;
    _booking.select(Stay(picked.start, picked.end));
  }

  Future<void> _useDates() async {
    final state = _booking.state;
    final stay = state.stay;
    if (stay == null) {
      _booking.missingDates();
      return;
    }
    final error = stay.validate(_booking.today);
    if (error != null) {
      _booking.select(stay);
      return;
    }
    if (state.isEditing) {
      final current = _trips.state.byId(state.editingTripId);
      if (current == null) {
        _goRoot('trips');
        return;
      }
      final warning = await _trips.changeDates(
        current,
        stay,
        notifyOwner: alertsOn,
      );
      _refreshNotifications();
      _booking.clear();
      if (!mounted) return;
      _goTrip(current.id, 'tripupdated');
      if (warning != null) notice(warning);
      return;
    }
    goTo('review');
  }

  Future<void> _book() async {
    final me = user;
    final stay = _booking.state.stay;
    if (me == null) return;
    if (stay == null) {
      goTo('dates');
      return;
    }
    final alerts = _booking.state.alerts;
    if (alerts != alertsOn) {
      final warning = await _profile.saveAlerts(me.uid, alerts);
      if (warning != null && mounted) notice(warning);
    }
    try {
      await _trips.book(
        user: me,
        site: campsite,
        stay: stay,
        alerts: alerts,
        plus: plus,
      );
    } on PlanLimitException {
      rethrow;
    } on StateError {
      rethrow;
    } catch (_) {
      goTo('request-not-sent');
      return;
    }
    _booking.clear();
    if (mounted) {
      context.goNamed('confirmed', pathParameters: {'siteId': campsite.id});
    }
  }

  Future<void> _share() async {
    final current = trip;
    if (current == null || !_valid()) return;
    final email = (fields['Invitation email'] ?? '').trim();
    String? warning;
    try {
      warning = await _trips.share(current, email);
    } on StateError {
      rethrow;
    } catch (_) {
      goTo('invitation-not-sent');
      return;
    }
    goTo('shared');
    if (warning != null && mounted) notice(warning);
  }

  Future<void> _openUpdate(String id) async {
    final matching = notifications.where((n) => n.id == id);
    if (matching.isEmpty) return;
    final note = matching.first;
    final me = user;
    if (me != null && !note.read) {
      unawaited(
        context
            .read<NotificationRepository>()
            .markRead(me.uid, id)
            .catchError((Object _) {}),
      );
    }
    final tripId = note.tripId;
    if (tripId != null && _trips.state.byId(tripId) != null) {
      _goTrip(tripId);
    } else {
      goTo('alertdetail', extra: note);
    }
  }

  void _openDownload(TripView? download) {
    if (download == null) {
      goTo('no-downloaded-trips');
      return;
    }
    _goTrip(
      download.id,
      download.record.downloadedDates == download.record.dates
          ? 'downloaded'
          : 'your-offline-copy-is-older',
    );
  }

  void _tab(int index) {
    if (guest && index > 0) {
      _authGate();
      return;
    }
    _goRoot(const ['explore', 'trips', 'saved', 'alerts', 'profile'][index]);
  }

  // ---- widgets the screens ask for ----

  @override
  Widget input(String label, String hint, String initial) {
    fields.putIfAbsent(label, () => initial);
    final optional = label == 'Your name';
    return TextFormField(
      key: ValueKey(label),
      initialValue: fields[label],
      obscureText: label == 'Password',
      keyboardType: label.toLowerCase().contains('email')
          ? TextInputType.emailAddress
          : TextInputType.text,
      autofillHints: switch (label) {
        'Email' => const [AutofillHints.email],
        'Password' => const [AutofillHints.password],
        _ => null,
      },
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (v) => fields[label] = v,
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return optional ? null : 'Enter $label';
        if (label.toLowerCase().contains('email') &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
          return 'Enter a valid email';
        }
        if (label == 'Password' &&
            route.startsWith('signup') &&
            value.length < 8) {
          return 'Use at least 8 characters';
        }
        return null;
      },
    );
  }

  @override
  Widget filter(String key) {
    final filters = _explore.state.filters;
    final choices = <String, List<String>>{
      'Site type': ['Tent', 'RV'],
      'Travelers': ['2 travelers', '4 travelers'],
      'Nightly budget': ['Any budget', 'Under \$55', 'Under \$70'],
      'Pet policy': ['Pet friendly', 'Any policy'],
    }[key]!;
    final selected = switch (key) {
      'Site type' => filters.siteType,
      'Travelers' => '${filters.travelers} travelers',
      'Nightly budget' =>
        filters.maxPrice == null ? 'Any budget' : 'Under \$${filters.maxPrice}',
      _ => filters.petsRequired ? 'Pet friendly' : 'Any policy',
    };
    return DropdownButtonFormField<String>(
      initialValue: selected,
      key: ValueKey('$key:$selected'),
      decoration: InputDecoration(labelText: key),
      items: [
        for (final v in choices) DropdownMenuItem(value: v, child: Text(v)),
      ],
      onChanged: (v) {
        if (v == null) return;
        _explore.setFilters(switch (key) {
          'Site type' => filters.copyWith(siteType: v),
          'Travelers' => filters.copyWith(
            travelers: int.parse(v.split(' ').first),
          ),
          'Nightly budget' => filters.copyWith(
            maxPrice: () =>
                v == 'Any budget' ? null : int.parse(v.substring(7)),
          ),
          _ => filters.copyWith(petsRequired: v == 'Pet friendly'),
        });
      },
    );
  }

  @override
  Widget alertSwitch(String label) {
    final onPreferences = route == 'preferences';
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(label),
      subtitle: const Text('Push alerts for invitations, dates and conditions'),
      value: onPreferences ? draftAlerts ?? alertsOn : _booking.state.alerts,
      onChanged: (v) {
        if (onPreferences) {
          setState(() => draftAlerts = v);
        } else {
          _booking.setAlerts(v);
        }
      },
    );
  }

  @override
  Widget areaMap() => CampsiteMap(
    onRedwood: () => _goSite('redwood-grove'),
    onSunset: () => _goSite('sunset-ridge'),
  );

  @override
  Widget brandMark(String asset, Widget caption) => Container(
    height: 160,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    decoration: BoxDecoration(
      color: softGreen,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 68,
          child: Center(child: Image.asset(asset, width: 53)),
        ),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: caption),
      ],
    ),
  );

  @override
  Widget profilePhoto() {
    final photo = _profile.state.photo;
    final initials = guest
        ? '?'
        : userName.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join();
    ImageProvider? image;
    if (photo != null && photo.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photo));
      } catch (_) {
        image = null;
      }
    }
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: softGreen,
          backgroundImage: image,
          child: image == null
              ? Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: forest,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => act('Take photo'),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take photo'),
              ),
              TextButton.icon(
                onPressed: () => act('Choose photo'),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose photo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget forecast({bool details = false}) {
    final site = campsite;
    final stay =
        trip?.record.stay ??
        (_booking.state.siteId == site.id ? _booking.state.stay : null);
    _forecast ??= context.read<WeatherRepository>().forecast(
      site.latitude,
      site.longitude,
      stay: stay,
    );
    return FutureBuilder<Forecast>(
      future: _forecast,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forecast unavailable',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Text(
                'Check your connection. Cached trip details still work offline.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              TextButton(
                onPressed: () => setState(() => _forecast = null),
                child: const Text('Retry forecast'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) return _ForecastShimmer(details: details);
        final f = snapshot.data!;
        final when = f.forTrip ? 'Your dates' : 'Next 3 days';
        if (!details) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$when · ${f.headline}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${f.high}° high · ${f.low}° low · ${f.maxRain}% chance of rain',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!f.forTrip)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  stay == null ? 'Next 3 days' : 'Your trip is more than 16 days away. Showing the next 3 days.',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
            SizedBox(
              height: 104,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final day in f.days)
                    Container(
                      width: 96,
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.dayLabel,
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                          Text(
                            day.summary,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${day.high}° / ${day.low}°',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${day.rainChance}% rain',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(f.packingTip),
            ),
            const SizedBox(height: 8),
            Text(
              'Rain chance up to ${f.maxRain}% · Wind up to ${f.maxWind} mph\nSource: Open-Meteo forecast',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ],
        );
      },
    );
  }

  // ---- layout ----

  int get _selectedTab => route.contains('saved')
      ? 2
      : route.startsWith('trip')
      ? 1
      : route.startsWith('alert')
      ? 3
      : route.startsWith('profile')
      ? 4
      : 0;

  void _onAuth(BuildContext context, AuthState state) {
    if (state is AuthFailure) {
      notice(state.message);
      return;
    }
    if (state is! AuthAuthenticated) return;
    final from = widget.from;
    if (from != null && from.isNotEmpty) {
      context.go(Uri.decodeComponent(from));
    } else if (route.startsWith('signup')) {
      context.goNamed('location');
    } else {
      context.goNamed('explore');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final tripsState = context.watch<TripsCubit>().state;
    context
      ..watch<SavedCubit>()
      ..watch<ProfileCubit>()
      ..watch<ExploreCubit>()
      ..watch<BookingCubit>()
      ..watch<NotificationsBloc>();

    if (route == 'splash' || route == 'splash-ready') {
      return SplashView(from: widget.from);
    }

    final waitingForTrip =
        widget.tripId != null && trip == null && !tripsState.isLoaded;
    final working = busy || auth is AuthLoading;
    final showTabs = widget.screen.tabs || _tabRoots.contains(route);
    final authRoute =
        route.startsWith('signin') ||
        route.startsWith('signup') ||
        route == 'authgate';

    final scaffold = AbsorbPointer(
      absorbing: working,
      child: Scaffold(
        bottomNavigationBar: showTabs && route != 'welcome'
            ? NavigationBar(
                height: 78,
                backgroundColor: Colors.white,
                indicatorColor: softGreen,
                selectedIndex: _selectedTab,
                onDestinationSelected: _tab,
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
              if (working) const LinearProgressIndicator(),
              if (localMode)
                const Text(
                  'Local demo · data disappears on restart',
                  style: TextStyle(fontSize: 11),
                ),
              if (tripsState.status == TripsStatus.failure)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(tripsState.error ?? ''),
                ),
              if (showDemo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: InkWell(
                    onTap: () => context.pushNamed('guide'),
                    child: const Text(
                      'Demo · Guide',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              if (waitingForTrip)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
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
                    child: AutofillGroup(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                        children: [
                          if (route == 'loading')
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          for (final section in widget.screen.body(this))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: section,
                            ),
                          if (route.startsWith('profile'))
                            TextButton(
                              onPressed: () => act('Refresh account'),
                              child: const Text('Refresh account'),
                            ),
                          if (route == 'guide')
                            ExpansionTile(
                              title: const Text('All prototype screens'),
                              children: [
                                for (final screen in campPages)
                                  ListTile(
                                    title: Text(
                                      screen.name.replaceAll(
                                        ' · Complete flow',
                                        '',
                                      ),
                                    ),
                                    onTap: () => context.go('/${screen.route}'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (route == 'detail' ||
                    route == 'guestdetail' ||
                    route == 'ridge')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Row(
                      children: [
                        Text(campsite.price),
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
            ],
          ),
        ),
      ),
    );
    if (!authRoute) return scaffold;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous is AuthLoading,
      listener: _onAuth,
      child: scaffold,
    );
  }
}

class _ForecastShimmer extends StatelessWidget {
  const _ForecastShimmer({required this.details});
  final bool details;

  @override
  Widget build(BuildContext context) {
    Widget box(double width, double height) => Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: details
          ? Row(children: [box(96, 104), box(96, 104), box(96, 104)])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [box(180, 16), box(220, 12)],
            ),
    );
  }
}
