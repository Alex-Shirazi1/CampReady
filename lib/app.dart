import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

import 'screens.dart';
import 'services/services.dart';
import 'campsite_map.dart';

class TripDetails {
  String dates = 'Oct 30–Nov 1, 2026', status = 'Request pending';
  String invitation = 'No invitations yet', downloadedDates = '';
}

class DemoState {
  DemoState({CampReadyServices? services})
    : services = services ?? CampReadyServices.local();

  /// First Integrations services (Auth / Firestore / FCM). In local
  /// mode these are backed by an in-memory store; in configured mode
  /// by Firebase. The UI uses this API either way.
  final CampReadyServices services;

  /// True when an account is signed in through AuthService. Tests and
  /// the guide preview can also set it directly; setting it true
  /// without an account keeps the previous profile fields.
  bool get signedIn =>
      services.auth.currentUser != null ||
      (!services.isFirebaseConfigured && _signedIn);
  set signedIn(bool value) {
    _signedIn = value;
  }

  final records = <String, TripRecord>{};
  String? accountUid;
  String? syncError;
  final changes = StreamController<void>.broadcast();
  int _loadVersion = 0;

  void changed() {
    if (!changes.isClosed) changes.add(null);
  }

  void clearAccount() {
    _loadVersion++;
    accountUid = null;
    _signedIn = false;
    name = '';
    email = '';
    plus = false;
    alerts = true;
    bookingAlerts = null;
    bookingDates = null;
    editingTrip = false;
    savedCampsiteIds.clear();
    trips.clear();
    details.clear();
    records.clear();
    notifications.clear();
    syncError = null;
    changed();
  }

  Future<void> loadAccount() async {
    final user = services.auth.currentUser;
    if (user == null) return;
    if (accountUid != user.uid) clearAccount();
    accountUid = user.uid;
    name = user.displayName ?? '';
    email = user.email;
    final version = ++_loadVersion;
    final saved = await services.firestore.savedCampsites(user.uid);
    final loadedTrips = await services.firestore.tripsForUser(
      user.uid,
      user.email,
    );
    final notes = await services.firestore.notifications(user.uid);
    final savedAlerts = await services.firestore.alertPreference(user.uid);
    final visibleTrips = <TripRecord>[];
    for (final record in loadedTrips) {
      if (record.ownerUid != user.uid) {
        final response = await services.firestore.invitationResponse(
          record.id,
          user.uid,
        );
        if (response?['status'] == 'declined') continue;
        visibleTrips.add(
          record.copyWith(
            invitation: response?['status'] == 'accepted'
                ? 'You joined the trip'
                : 'Invitation pending · ${user.email}',
          ),
        );
      } else {
        final responses = await services.firestore.invitationResponses(
          record.id,
        );
        final current = responses.where(
          (r) => record.sharedWithEmails.contains(r['email']),
        );
        visibleTrips.add(
          current.isEmpty
              ? record
              : record.copyWith(
                  invitation: current
                      .map((r) => "${r['email']}: ${r['status']}")
                      .join(' · '),
                ),
        );
      }
    }
    if (version != _loadVersion || services.auth.currentUser?.uid != user.uid) {
      return;
    }
    final grouped = <String, List<TripRecord>>{};
    for (final record in visibleTrips) {
      grouped.putIfAbsent(record.site, () => []).add(record);
    }
    final conflicts = grouped.entries.where((entry) => entry.value.length > 1);
    syncError = conflicts.isEmpty
        ? null
        : 'More than one trip was shared for ${conflicts.map((e) => e.key).join(', ')}. '
              'Resolve the duplicate with the owner; no trip was overwritten.';
    savedCampsiteIds
      ..clear()
      ..addAll(saved.map((site) => site.siteId));
    trips.clear();
    records.clear();
    details.clear();
    for (final entry in grouped.entries) {
      if (entry.value.length != 1) continue;
      final record = entry.value.single;
      trips.add(record.site);
      records[record.site] = record;
      details[record.site] = TripDetails()
        ..dates = record.dates
        ..status = record.status
        ..invitation = record.invitation
        ..downloadedDates = record.downloadedDates;
    }
    alerts = savedAlerts;
    notifications
      ..clear()
      ..addAll(notes);
    notifications.sort(
      (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    );
    changed();
  }

  bool _signedIn = false;
  bool plus = false, alerts = true;
  bool editingTrip = false;
  bool? bookingAlerts;
  String? bookingDates;
  String destination = '';
  String site = 'Redwood Grove';
  // Profile fields. Empty until an account signs in; populated from
  // AuthService / Firestore, never from a hardcoded sample name.
  String name = '', email = '';
  // Campsites saved through FirestoreService (local store in local
  // mode), keyed by site id. `saved` is the per-site view of this set.
  final Set<String> savedCampsiteIds = {};
  bool get saved => savedCampsiteIds.contains(site);
  set saved(bool value) {
    if (value) {
      savedCampsiteIds.add(site);
    } else {
      savedCampsiteIds.remove(site);
    }
  }

  /// Notification records delivered for this account (MessagingService
  /// / Firestore), newest first. Empty until a condition changes or an
  /// invitation arrives; never hardcoded alert panels.
  final List<AppNotification> notifications = [];
  final details = <String, TripDetails>{};
  TripDetails get trip => details[site] ?? TripDetails();
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
    this.services,
  });
  final String initialRoute;
  final DemoState? initialState;
  final CampReadyServices? services;
  @override
  State<CampReady> createState() => _CampReadyState();
}

class _CampReadyState extends State<CampReady> {
  late final demo = widget.initialState ?? DemoState(services: widget.services);
  late final router = GoRouter(
    initialLocation: widget.initialRoute,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      for (final s in campPages)
        GoRoute(
          path: '/${s.route}',
          name: s.route,
          redirect: (_, state) {
            // Named demo previews have no saved-trip context. Real trip
            // navigation retains it, including restored browser history.
            if (state.extra is String &&
                const {
                  'trip',
                  'ridgetrip',
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
                  'downloaded',
                  'save-for-offline-use',
                  'ready-for-offline-use',
                  'your-offline-copy-is-older',
                }.contains(s.route) &&
                !demo.trips.contains(state.extra)) {
              return '/this-trip-is-no-longer-available';
            }
            return null;
          },
          builder: (_, state) => DesignScreen(
            key: state.pageKey,
            screen: s,
            demo: demo,
            initialSite: state.extra as String?,
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
  StreamSubscription<AppUser?>? authSubscription;
  StreamSubscription<AppNotification>? messageSubscription;

  @override
  void initState() {
    super.initState();
    authSubscription = demo.services.auth.authStateChanges.listen((user) {
      final messaging = demo.services.messaging;
      if (messaging.registeredUid != null &&
          messaging.registeredUid != user?.uid) {
        unawaited(
          messaging.detachUser().catchError((Object error) {
            messaging.status = 'Push cleanup failed; retry notification setup';
          }),
        );
      }
      if (user == null && demo.accountUid != null) demo.clearAccount();
      if (user != null && user.uid != demo.accountUid) restoreAccount();
    });
    messageSubscription = demo.services.messaging.onMessage.listen((note) {
      final uid = demo.services.auth.currentUser?.uid;
      if (uid == null) return;
      if (demo.services.isFirebaseConfigured &&
          demo.services.messaging.registeredUid != uid) {
        return;
      }
      if (!demo.notifications.any((n) => n.id == note.id)) {
        demo.notifications.insert(0, note);
        demo.changed();
      }
    });
    if (demo.services.auth.currentUser != null) restoreAccount();
  }

  Future<void> restoreAccount() async {
    try {
      await demo.loadAccount();
      final user = demo.services.auth.currentUser;
      if (user != null && demo.alerts) {
        unawaited(
          demo.services.messaging.restoreRegistration(user.uid).catchError((
            Object error,
          ) {
            demo.services.messaging.status =
                'Push registration could not be restored';
          }),
        );
      }
    } catch (_) {
      demo.syncError =
          'Could not load your saved data. Retry from your profile.';
      demo.changed();
    }
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    messageSubscription?.cancel();
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
    required this.demo,
    this.initialSite,
  });
  final CampPage screen;
  final DemoState demo;
  final String? initialSite;
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
  StreamSubscription<void>? stateSubscription;
  bool busy = false;
  late String site;
  String? draftDates;
  bool? draftAlerts;
  @override
  bool get ridgeMatch => d.siteType == 'RV' && d.pets == 'Any policy';
  String get route => widget.screen.route;
  DemoState get d => widget.demo;
  TripDetails get trip => d.details[site] ?? TripDetails();

  void selectSite(String value) {
    site = value;
    d.site = value;
  }

  String get tripRoute => site == 'Sunset Ridge' ? 'ridgetrip' : 'trip';
  String get reviewRoute => site == 'Sunset Ridge' ? 'ridgereview' : 'review';
  @override
  void initState() {
    super.initState();
    stateSubscription = d.changes.stream.listen((_) {
      if (mounted) setState(() {});
    });
    site =
        widget.initialSite ??
        switch (route) {
          'ridge' ||
          'ridgereview' ||
          'ridgeconfirmed' ||
          'ridgetrip' => 'Sunset Ridge',
          'detail' ||
          'guestdetail' ||
          'review' ||
          'confirmed' ||
          'trip' => 'Redwood Grove',
          _ => d.site,
        };
    selectSite(site);
    if (route.startsWith('splash')) {
      splashAnimation = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward();
    }
    if (route.startsWith('splash') || route == 'loading') {
      timer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          context.goNamed(
            route == 'loading' || d.signedIn ? 'explore' : 'welcome',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    stateSubscription?.cancel();
    splashAnimation?.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  void goTo(String target) {
    if (!mounted) return;
    if (target == 'profile' && d.plus) target = 'profileplus';
    if (target == 'trips' && d.trips.isEmpty) target = 'tripsempty';
    if (target == 'alerts' && (d.trips.isEmpty || !d.alerts)) {
      target = 'alertsempty';
    }
    if (target == 'explore' && guest) target = 'guest';
    context.pushNamed(target, extra: site);
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

  String get _ownerUid => d.services.auth.currentUser?.uid ?? 'local_guest';
  String get _ownerEmail => d.services.auth.currentUser?.email ?? d.email;
  String _tripIdFor(String siteName) =>
      d.records[siteName]?.id ??
      'trip_${_ownerUid}_${siteName.replaceAll(' ', '_')}';

  TripRecord _tripRecord(String siteName) {
    final details = d.details[siteName] ?? TripDetails();
    final existing = d.records[siteName];
    if (existing != null && existing.ownerUid != _ownerUid) {
      throw StateError(
        'Shared trips are view-only. Ask the owner to change this trip.',
      );
    }
    return TripRecord(
      id: _tripIdFor(siteName),
      ownerUid: _ownerUid,
      ownerEmail: _ownerEmail,
      site: siteName,
      dates: details.dates,
      status: details.status,
      alertsEnabled: d.alerts,
      downloadedDates: details.downloadedDates,
      sharedWithEmails: existing?.sharedWithEmails ?? [],
      invitation: details.invitation,
    );
  }

  Future<void> _persistTrip(String siteName) async {
    final record = _tripRecord(siteName);
    if (d.records.containsKey(siteName)) {
      await d.services.firestore.updateTrip(record);
    } else {
      await d.services.firestore.createTrip(record);
    }
    d.records[siteName] = record;
  }

  Future<void> _notifyConditionChange(String title, String body) async {
    if (!d.alerts) return;
    try {
      final note = await d.services.messaging.notifyConditionChange(
        ownerUid: _ownerUid,
        ownerEmail: _ownerEmail,
        tripId: _tripIdFor(site),
        site: site,
        title: title,
        body: body,
      );
      if (!d.notifications.any((n) => n.id == note.id)) {
        d.notifications.insert(0, note);
      }
      d.changed();
    } catch (_) {
      if (mounted) {
        notice('Trip saved, but its update notification could not be saved.');
      }
    }
  }

  Future<void> _enableNotifications() async {
    final user = d.services.auth.currentUser;
    if (user == null) return;
    final granted = await d.services.messaging.requestPermission();
    if (!granted) throw StateError(d.services.messaging.status);
    final token = await d.services.messaging.getToken(user.uid);
    if (token == null) {
      throw StateError(
        'Push registration failed. Check the messaging setup and retry.',
      );
    }
  }

  Future<void> _shareTrip(String inviteEmail) async {
    _tripRecord(site);
    await _persistTrip(site);
    final updated = await d.services.firestore.shareTrip(
      tripId: _tripIdFor(site),
      email: inviteEmail,
    );
    d.records[site] = updated;
    trip.invitation = updated.invitation;
  }

  Future<void> _applyAuthUser(AppUser user) async {
    await d.loadAccount();
    await d.services.firestore.saveUserProfile(user);
  }

  Future<void> _runAction(String label, String? destination) async {
    if (busy) return;
    final actionUid = d.services.auth.currentUser?.uid;
    final oldTrips = Set<String>.of(d.trips);
    final oldRecords = Map<String, TripRecord>.of(d.records);
    final oldDetails = {
      for (final entry in d.details.entries)
        entry.key: TripDetails()
          ..dates = entry.value.dates
          ..status = entry.value.status
          ..invitation = entry.value.invitation
          ..downloadedDates = entry.value.downloadedDates,
    };
    final oldAlerts = d.alerts;
    final oldBookingDates = d.bookingDates;
    final oldBookingAlerts = d.bookingAlerts;
    final oldEditingTrip = d.editingTrip;
    setState(() => busy = true);
    try {
      await _performAction(label, destination);
    } catch (error) {
      if (d.services.auth.currentUser?.uid != actionUid) return;
      d.trips
        ..clear()
        ..addAll(oldTrips);
      d.records
        ..clear()
        ..addAll(oldRecords);
      d.details
        ..clear()
        ..addAll(oldDetails);
      d.alerts = oldAlerts;
      d.bookingDates = oldBookingDates;
      d.bookingAlerts = oldBookingAlerts;
      d.editingTrip = oldEditingTrip;
      if (mounted) {
        notice(
          error is TimeoutException
              ? 'The connection timed out. A queued change may still save when you reconnect. Refresh before trying again.'
              : error is StateError
              ? error.message.toString()
              : 'Could not complete this action. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void act(String label, [String? destination]) {
    unawaited(_runAction(label, destination));
  }

  Future<void> _performAction(String label, String? destination) async {
    if (d.records[site] != null &&
        d.records[site]!.ownerUid != _ownerUid &&
        [
          'Edit dates',
          'Use selected dates',
          'Remove trip',
          'Send invitation',
          'Revoke invitation',
          'Host accepts',
          'Host declines',
          'No response in 24 hours',
          'Request again',
          'Request to book · Demo',
          'Retry request',
        ].contains(label)) {
      throw StateError(
        'Shared trips are view-only. Ask the owner to change this trip.',
      );
    }
    if (label == '‹ Back' || label == 'Back') {
      back();
      return;
    }
    if ([
          'Send invitation',
          'Accept invitation',
          'Decline invitation',
          'Revoke invitation',
          'Edit dates',
          'Remove trip',
          'Host accepts',
          'Host declines',
          'No response in 24 hours',
          'Request again',
          'Download summary',
          'Refresh download',
          'Refresh while online',
          'Complete download',
          'Delete downloaded copy',
        ].contains(label) &&
        !d.trips.contains(site)) {
      goTo('this-trip-is-no-longer-available');
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
      // Real auth: Firebase Auth when configured, the local auth store
      // otherwise. A failed sign-in lands on the Figma error screen.
      final email = fields['Email'] ?? d.email;
      final password = fields['Password'] ?? '';
      final auth = d.services.auth;
      try {
        final user = label == 'Create account'
            ? await auth.signUp(
                email: email,
                password: password,
                displayName: fields['Your name'],
              )
            : await auth.signIn(email: email, password: password);
        await _applyAuthUser(user);
        if (mounted) goTo('location');
      } on AuthException catch (error) {
        if (mounted) notice(error.message);
      }
      return;
    }
    if (label == 'Send reset link' ||
        label == 'Send invitation' ||
        label == 'Save profile') {
      if (!(form.currentState?.validate() ?? true)) {
        return;
      }
      if (label == 'Save profile') {
        final name = fields['Display name'] ?? d.name;
        final user = d.services.auth.currentUser;
        if (user != null) {
          final updated = await d.services.auth.updateDisplayName(name);
          if (updated != null) {
            await d.services.firestore.saveUserProfile(updated);
          }
        }
        d.name = name;
        if (mounted) goTo('profilesaved');
      }
      if (label == 'Send reset link') {
        await d.services.auth.sendPasswordReset(fields['Email'] ?? d.email);
        if (mounted) goTo('resetsent');
      }
      if (label == 'Send invitation') {
        final inviteEmail = (fields['Invitation email'] ?? '')
            .trim()
            .toLowerCase();
        if (inviteEmail == _ownerEmail.toLowerCase()) {
          throw StateError('This is already your trip. Invite another person.');
        }
        await _shareTrip(inviteEmail);
        if (mounted) goTo('shared');
      }
      return;
    }
    if (label == 'Sign out' && route == 'signout') {
      await d.services.messaging.detachUser();
      await d.services.auth.signOut();
      d.clearAccount();
      if (mounted) context.goNamed('welcome');
      return;
    }
    if (label == 'People on this trip' && d.services.auth.currentUser != null) {
      await d.loadAccount();
      if (!d.trips.contains(site)) {
        goTo('this-trip-is-no-longer-available');
        return;
      }
    }
    if (label == 'Refresh account') {
      await d.loadAccount();
      return;
    }
    if (label == 'Get started' || label == 'Explore as a guest') {
      if (d.services.auth.currentUser != null) {
        await d.services.messaging.detachUser();
        await d.services.auth.signOut();
      }
      d.clearAccount();
      goTo('guest');
      return;
    }
    if (label == 'Empty trips') {
      d.trips.clear();
      d.details.clear();
    }
    if (label.startsWith('Open saved: ')) {
      selectSite(label.substring('Open saved: '.length));
      goTo(site == 'Sunset Ridge' ? 'ridge' : 'detail');
      return;
    }
    if (label.startsWith('Remove saved: ')) {
      final savedSite = label.substring('Remove saved: '.length);
      final user = d.services.auth.currentUser;
      if (user != null) {
        await d.services.firestore.removeCampsite(user.uid, savedSite);
      }
      d.savedCampsiteIds.remove(savedSite);
      goTo(d.savedCampsiteIds.isEmpty ? 'savedempty' : 'saved');
      return;
    }
    if (label == 'Empty saved' ||
        label == 'Remove Redwood Grove' ||
        label == 'Remove from saved') {
      final user = d.services.auth.currentUser;
      if (user != null) {
        await d.services.firestore.removeCampsite(user.uid, site);
      }
      d.saved = false;
    }
    if (label == 'Save campsite') {
      if (guest) {
        goTo('authgate');
      } else {
        final user = d.services.auth.currentUser;
        if (user != null) {
          await d.services.firestore.saveCampsite(
            user.uid,
            SavedCampsite(
              siteId: site,
              name: site,
              pricePerNight: site == 'Sunset Ridge'
                  ? r'$55 / night'
                  : r'$65 / night',
            ),
          );
        }
        d.saved = true;
        if (mounted) goTo('detailsaved');
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
        d.bookingDates = trip.dates;
        goTo('dates');
      }
      return;
    }
    if (label == 'Trip Conditions' || label == 'View conditions') {
      goTo(site == 'Sunset Ridge' ? 'unknown' : 'conditions');
      return;
    }
    if (label == 'Enable trip updates' && guest) {
      goTo('authgate');
      return;
    }
    if (label == 'Edit dates') {
      d.editingTrip = true;
      d.bookingDates = trip.dates;
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
      d.bookingDates = draftDates ?? d.bookingDates ?? trip.dates;
      if (d.editingTrip) {
        trip.dates = d.bookingDates!;
        await _persistTrip(site);
        await _notifyConditionChange(
          '$site: dates changed',
          'Your trip dates are now ${trip.dates}.',
        );
      }
      goTo(d.editingTrip ? 'tripupdated' : reviewRoute);
      return;
    }
    if (label == 'Allow notifications' || label == 'Not now') {
      d.bookingAlerts = label == 'Allow notifications';
      goTo(reviewRoute);
      return;
    }
    if (label == 'Request to book · Demo' || label == 'Retry request') {
      if (d.trips.isNotEmpty && !d.trips.contains(site) && !d.plus) {
        goTo('premium');
        return;
      }
      d.trips.add(site);
      d.details.putIfAbsent(site, TripDetails.new);
      final previousAlerts = d.alerts;
      d.alerts = d.bookingAlerts ?? d.alerts;
      d.bookingAlerts = null;
      trip.dates = d.bookingDates ?? trip.dates;
      d.bookingDates = null;
      trip.status = 'Request pending';
      // First Integrations: the trip now lives in Firestore (local
      // store in local mode), so it can be shared and synced.
      await _persistTrip(site);
      final user = d.services.auth.currentUser;
      if (user != null) {
        try {
          await d.services.firestore.saveAlertPreference(user.uid, d.alerts);
        } catch (_) {
          d.alerts = previousAlerts;
          if (mounted) {
            notice(
              'Trip saved, but notification preferences could not be saved.',
            );
          }
        }
      }
      goTo(site == 'Sunset Ridge' ? 'ridgeconfirmed' : 'confirmed');
      return;
    }
    if (label == 'Remove trip' && route == 'remove') {
      _tripRecord(site);
      await d.services.firestore.deleteTrip(_tripIdFor(site));
      d.records.remove(site);
      d.trips.remove(site);
      d.details.remove(site);
      if (d.trips.isNotEmpty) selectSite(d.trips.first);
      if (mounted) {
        context.goNamed(d.trips.isEmpty ? 'tripsempty' : 'trips', extra: site);
      }
      return;
    }
    if (label == 'Host accepts' ||
        label == 'Host declines' ||
        label == 'No response in 24 hours' ||
        label == 'Request again') {
      final status = {
        'Host accepts': 'Accepted',
        'Host declines': 'Declined',
        'No response in 24 hours': 'Expired',
        'Request again': 'Request pending',
      }[label]!;
      setState(() => trip.status = status);
      await _persistTrip(site);
      await _notifyConditionChange(
        '$site: booking $status',
        'Your trip request is now $status.',
      );
      notice('Demo booking: ${trip.status}');
      return;
    }
    if (label == 'Accept invitation' || label == 'Decline invitation') {
      final record = d.records[site];
      final user = d.services.auth.currentUser;
      if (record != null && user != null && record.ownerUid != user.uid) {
        await d.services.firestore.respondToInvitation(
          record,
          user,
          label == 'Accept invitation' ? 'accepted' : 'declined',
        );
      } else if (d.services.isFirebaseConfigured) {
        throw StateError('Sign in as the invited person to respond.');
      }
      trip.invitation = label == 'Accept invitation'
          ? (record != null && record.ownerUid != user?.uid
                ? 'You joined the trip'
                : 'Friend joined')
          : 'Invitation declined';
      if (label == 'Decline invitation' &&
          record != null &&
          record.ownerUid != user?.uid) {
        d.trips.remove(site);
        d.records.remove(site);
      }
      goTo(
        label == 'Accept invitation'
            ? 'you-joined-the-trip'
            : 'invitation-declined',
      );
      return;
    }
    if (label == 'Revoke invitation') {
      _tripRecord(site);
      final record = d.records[site];
      if (record != null) {
        d.records[site] = await d.services.firestore.revokeInvitations(record);
      }
      trip.invitation = 'Invitation revoked';
      goTo('this-invitation-is-unavailable');
      return;
    }
    if (label == 'Refresh shared plan') {
      await d.loadAccount();
      if (!mounted) return;
      if (!d.trips.contains(site)) {
        goTo('this-invitation-is-unavailable');
        return;
      }
      final record = d.records[site];
      if (record != null &&
          record.ownerUid != d.services.auth.currentUser?.uid) {
        openTrip();
      }
      notice('Shared plan refreshed.');
      if (mounted) setState(() {});
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
      trip.downloadedDates = trip.dates;
    }
    if (label == 'Delete downloaded copy') {
      trip.downloadedDates = '';
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
      selectSite(label);
      openTrip();
      return;
    }
    if (label == 'Sunset Ridge') {
      selectSite('Sunset Ridge');
    }
    if (label == 'Campsite card' || label == 'Redwood Grove') {
      selectSite('Redwood Grove');
    }
    if (label == 'Explore and plan' ||
        label == 'Trips and group sharing' ||
        label == 'Account and Plus') {
      if (d.services.isFirebaseConfigured && guest) {
        goTo('authgate');
        return;
      }
      d.signedIn = true;
    }
    if (label == 'Trips and group sharing') {
      selectSite('Redwood Grove');
      d.trips.add(site);
      d.details.putIfAbsent(site, TripDetails.new);
    }
    if (label == 'Open downloaded trip' && d.downloads.isNotEmpty) {
      if (!d.downloads.contains(site)) selectSite(d.downloads.first);
      goTo(
        trip.downloadedDates == trip.dates
            ? 'downloaded'
            : 'your-offline-copy-is-older',
      );
      return;
    }
    if (label == 'Save preferences') {
      final enabled = draftAlerts ?? d.alerts;
      final user = d.services.auth.currentUser;
      if (user != null) {
        await d.services.firestore.saveAlertPreference(user.uid, enabled);
      }
      d.alerts = enabled;
      try {
        if (enabled) {
          await _enableNotifications();
        } else {
          await d.services.messaging.detachUser();
        }
      } catch (error) {
        if (mounted) {
          notice(
            'Preferences saved. Push setup could not be updated: ${error is StateError ? error.message : 'check your connection and retry'}',
          );
        }
      }
    }
    if (label == 'Redwood: fire restriction') selectSite('Redwood Grove');
    if (label == 'Sunset: conditions unconfirmed') selectSite('Sunset Ridge');
    if (label == 'View affected trip') selectSite('Redwood Grove');
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
      'Trip conditions': site == 'Sunset Ridge' ? 'unknown' : 'tripconditions',
      'Manage alerts': 'preferences',
      'All updates': 'alerts',
      'Done': route == 'profilesaved'
          ? (d.plus ? 'profileplus' : 'profileupdated')
          : 'alerts',
      'Enable trip updates': 'notifprompt',
      'Allow notifications': reviewRoute,
      'Not now': reviewRoute,
      'View saved campsites': d.savedCampsiteIds.isNotEmpty
          ? 'saved'
          : 'savedempty',
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
      value = value.replaceAll('Redwood Grove', site);
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
      // Profile screens render the signed-in account's name from
      // AuthService / Firestore, not a hardcoded sample name.
      value = d.services.auth.currentUser?.displayName ?? d.name;
      if (value.isEmpty) value = 'Not signed in';
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
        planning ? draftDates ?? d.bookingDates ?? trip.dates : trip.dates,
      );
    }
    if (value.startsWith('Request pending')) {
      value = '${trip.status} · Demo';
    }
    return value;
  }

  @override
  String noticeValue(String name, String fallback) {
    switch (name) {
      case 'Notice / Name':
        final displayName = d.services.auth.currentUser?.displayName ?? d.name;
        return displayName.isEmpty ? 'Not signed in' : displayName;
      case 'Notice / Email':
        final accountEmail = d.services.auth.currentUser?.email ?? d.email;
        return accountEmail.isEmpty ? 'Not signed in' : accountEmail;
      case 'Notice / People':
        return trip.invitation;
      case 'Notice / Downloaded dates':
        return trip.downloadedDates.isEmpty
            ? 'No offline copy saved'
            : trip.downloadedDates;
      case 'Notice / Booking status':
        return '${trip.status} · Demo';
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
  List<String> get savedSites => d.savedCampsiteIds.toList();

  @override
  bool get hasRedwoodAlert => d.trips.contains('Redwood Grove');

  @override
  List<AppNotification> get notifications => d.notifications;

  @override
  String get backendMode => d.services.mode;

  @override
  Widget areaMap() => CampsiteMap(
    onRedwood: () {
      selectSite('Redwood Grove');
      goTo('detail');
    },
    onSunset: () {
      selectSite('Sunset Ridge');
      goTo('ridge');
    },
  );

  void openTrip() {
    final record = d.records[site];
    if (record != null && record.ownerUid != _ownerUid) {
      goTo(
        trip.invitation == 'You joined the trip'
            ? 'you-joined-the-trip'
            : 'you-re-invited',
      );
    } else {
      goTo(tripRoute);
    }
  }

  void tab(int index) {
    unawaited(_openTab(index));
  }

  Future<void> _openTab(int index) async {
    if (!d.signedIn) {
      if (index == 0) {
        context.goNamed('guest');
        return;
      }
      goTo('authgate');
      return;
    }
    if (d.services.auth.currentUser != null) {
      if (busy) return;
      setState(() => busy = true);
      try {
        await d.loadAccount();
      } catch (_) {
        if (mounted) {
          notice(
            'Could not refresh your account. Check your connection and retry.',
          );
        }
        return;
      } finally {
        if (mounted) setState(() => busy = false);
      }
      if (!mounted) return;
    }
    final routes = [
      'explore',
      d.trips.isEmpty ? 'tripsempty' : 'trips',
      d.savedCampsiteIds.isNotEmpty ? 'saved' : 'savedempty',
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
    return AbsorbPointer(
      absorbing: busy,
      child: Scaffold(
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
              if (busy) const LinearProgressIndicator(),
              if (!d.services.isFirebaseConfigured)
                const Text(
                  'Local demo · data disappears on restart',
                  style: TextStyle(fontSize: 11),
                ),
              if (d.syncError != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(d.syncError!),
                ),
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
                            selectSite('Sunset Ridge');
                            goTo('unknown');
                          },
                        ),
                      if (route == 'trips')
                        for (final site in d.trips)
                          Card(
                            child: ListTile(
                              title: Text(site),
                              subtitle: Text(
                                d.details[site]?.dates ?? TripDetails().dates,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                selectSite(site);
                                openTrip();
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
                              selectSite(site);
                              goTo(
                                trip.downloadedDates == trip.dates
                                    ? 'downloaded'
                                    : 'your-offline-copy-is-older',
                              );
                            },
                            child: Text(
                              '$site · ${d.details[site]!.downloadedDates}',
                            ),
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
                                onTap: () => context.pushNamed(screen.route),
                              ),
                          ],
                        ),
                      if (route == 'booking-response')
                        Text('Demo booking status: ${trip.status}'),
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
      ),
    );
  }
}
