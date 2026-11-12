import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/notification_repository.dart';
import '../../repositories/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.profileRepository, this.notificationRepository)
    : super(const ProfileState());

  final ProfileRepository profileRepository;
  final NotificationRepository notificationRepository;
  int _loadVersion = 0;

  Future<void> load(String uid) async {
    final version = ++_loadVersion;
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final settings = await profileRepository.load(uid);
      if (version != _loadVersion) return;
      emit(ProfileState(status: ProfileStatus.ready, settings: settings));
      // Like the class NotificationsBloc: ask for permission at start-up
      // and register this device, so a new user with alerts on gets pushes.
      if (settings.alertsEnabled) {
        try {
          await notificationRepository.enablePush(uid);
        } catch (_) {}
      }
    } catch (_) {
      if (version != _loadVersion) return;
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          error: 'Could not load your profile. Check your connection.',
        ),
      );
    }
  }

  void clear() {
    _loadVersion++;
    emit(const ProfileState());
  }

  /// Saves the alert preference and registers or removes this device's
  /// push token. Returns a warning when push could not be updated.
  Future<String?> saveAlerts(String uid, bool enabled) async {
    await profileRepository.setAlerts(uid, enabled);
    emit(
      state.copyWith(
        settings: ProfileSettings(
          alertsEnabled: enabled,
          plus: state.settings.plus,
          photo: state.settings.photo,
        ),
      ),
    );
    try {
      if (enabled) {
        await notificationRepository.enablePush(uid);
      } else {
        await notificationRepository.disablePush();
      }
      return null;
    } on StateError catch (e) {
      return 'Preferences saved. Push was not turned on: ${e.message}';
    } catch (_) {
      return 'Preferences saved. Push setup failed; check your connection.';
    }
  }

  /// Simulated upgrade: no payment is collected.
  Future<void> setPlus(String uid, bool plus) async {
    await profileRepository.setPlus(uid, plus);
    emit(
      state.copyWith(
        settings: ProfileSettings(
          alertsEnabled: state.settings.alertsEnabled,
          plus: plus,
          photo: state.settings.photo,
        ),
      ),
    );
  }

  Future<void> setPhoto(String uid, String photo) async {
    await profileRepository.setPhoto(uid, photo);
    emit(
      state.copyWith(
        settings: ProfileSettings(
          alertsEnabled: state.settings.alertsEnabled,
          plus: state.settings.plus,
          photo: photo,
        ),
      ),
    );
  }
}
