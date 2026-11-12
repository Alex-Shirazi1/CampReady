import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/booking/booking_cubit.dart';
import 'blocs/explore/explore_cubit.dart';
import 'blocs/notifications/notifications_bloc.dart';
import 'blocs/profile/profile_cubit.dart';
import 'blocs/saved/saved_cubit.dart';
import 'blocs/trips/trips_cubit.dart';
import 'repositories/auth_repository.dart';
import 'repositories/campsite_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/trip_repository.dart';
import 'repositories/weather_repository.dart';
import 'router.dart';
import 'services/services.dart';
import 'theme.dart';

class CampReady extends StatefulWidget {
  const CampReady({
    super.key,
    this.initialRoute = '/splash',
    this.services,
    this.locationRepository,
    this.weatherRepository,
    this.clock,
  });

  final String initialRoute;
  final CampReadyServices? services;
  final LocationRepository? locationRepository;
  final WeatherRepository? weatherRepository;
  final DateTime Function()? clock;

  @override
  State<CampReady> createState() => _CampReadyState();
}

class _CampReadyState extends State<CampReady> {
  late final CampReadyServices services =
      widget.services ?? CampReadyServices.local();

  late final authRepository = AuthRepository(
    services.auth,
    services.firestore,
    services.messaging,
  );
  late final campsiteRepository = CampsiteRepository(services.firestore);
  late final tripRepository = TripRepository(
    services.firestore,
    services.messaging,
  );
  late final profileRepository = ProfileRepository(services.firestore);
  late final notificationRepository = NotificationRepository(
    services.messaging,
    services.firestore,
  );
  late final locationRepository =
      widget.locationRepository ?? LocationRepository();
  late final weatherRepository =
      widget.weatherRepository ?? WeatherRepository(clock: widget.clock);

  late final authBloc = AuthBloc(authRepository);
  late final tripsCubit = TripsCubit(tripRepository);
  late final savedCubit = SavedCubit(campsiteRepository);
  late final profileCubit = ProfileCubit(
    profileRepository,
    notificationRepository,
  );
  late final exploreCubit = ExploreCubit(
    campsiteRepository,
    locationRepository,
  );
  late final bookingCubit = BookingCubit(clock: widget.clock);
  late final notificationsBloc = NotificationsBloc(notificationRepository);

  late final GoRouter router = buildRouter(
    initialLocation: widget.initialRoute,
    auth: authBloc,
    trips: tripsCubit,
    campsites: campsiteRepository,
  );

  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _loadedUid;

  /// Loads or clears every account-scoped bloc when the session changes.
  void _onAuthChanged(BuildContext context, AuthState state) {
    final user = state.user;
    if (state is AuthAuthenticated && user != null) {
      if (state.message != null) _show(state.message!);
      if (_loadedUid == user.uid) return;
      _loadedUid = user.uid;
      tripsCubit.load(user);
      savedCubit.load(user.uid);
      profileCubit.load(user.uid);
      notificationsBloc.add(NotificationsStarted(user));
    } else if (state is AuthUnauthenticated && _loadedUid != null) {
      _loadedUid = null;
      tripsCubit.clear();
      savedCubit.clear();
      profileCubit.clear();
      bookingCubit.clear();
      notificationsBloc.add(NotificationsStopped());
    }
  }

  void _onNotification(BuildContext context, NotificationsState state) {
    final note = state.latest;
    if (note == null) return;
    final user = authBloc.state.user;
    if (user != null) tripsCubit.load(user);
    final tripId = note.tripId;
    if (state.latestType == NotificationType.onMessage) {
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (note.body.isNotEmpty) Text(note.body),
            ],
          ),
          action: tripId == null
              ? null
              : SnackBarAction(
                  label: 'View',
                  onPressed: () => router.go('/trips/$tripId'),
                ),
        ),
      );
    } else if (tripId != null) {
      router.go('/trips/$tripId');
    }
  }

  void _show(String text) =>
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    router.dispose();
    authBloc.close();
    tripsCubit.close();
    savedCubit.close();
    profileCubit.close();
    exploreCubit.close();
    bookingCubit.close();
    notificationsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: campsiteRepository),
        RepositoryProvider.value(value: tripRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: notificationRepository),
        RepositoryProvider.value(value: locationRepository),
        RepositoryProvider.value(value: weatherRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: tripsCubit),
          BlocProvider.value(value: savedCubit),
          BlocProvider.value(value: profileCubit),
          BlocProvider.value(value: exploreCubit),
          BlocProvider.value(value: bookingCubit),
          BlocProvider.value(value: notificationsBloc),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(listener: _onAuthChanged),
            BlocListener<TripsCubit, TripsState>(
              listenWhen: (previous, current) =>
                  current.isLoaded &&
                  previous.trips.map((t) => t.id).toSet().toString() !=
                      current.trips.map((t) => t.id).toSet().toString(),
              listener: (context, state) => notificationsBloc.add(
                NotificationsRefreshRequested(
                  tripIds: {for (final t in state.trips) t.id},
                ),
              ),
            ),
            BlocListener<NotificationsBloc, NotificationsState>(
              listenWhen: (previous, current) =>
                  current.received != previous.received,
              listener: _onNotification,
            ),
          ],
          child: MaterialApp.router(
            title: 'CampReady',
            debugShowCheckedModeBanner: false,
            theme: campTheme(),
            scaffoldMessengerKey: messengerKey,
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
          ),
        ),
      ),
    );
  }
}
