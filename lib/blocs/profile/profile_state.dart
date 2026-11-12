part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, ready, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.settings = const ProfileSettings(),
    this.error,
  });

  final ProfileStatus status;
  final ProfileSettings settings;
  final String? error;

  bool get plus => settings.plus;
  bool get alertsEnabled => settings.alertsEnabled;
  String? get photo => settings.photo;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileSettings? settings,
    String? error,
  }) => ProfileState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    error: error,
  );

  @override
  List<Object?> get props => [status, settings, error];
}
