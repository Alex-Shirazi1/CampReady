import 'package:equatable/equatable.dart';

import '../services/services.dart';

class ProfileSettings extends Equatable {
  const ProfileSettings({
    this.alertsEnabled = true,
    this.plus = false,
    this.photo,
  });

  final bool alertsEnabled;

  /// CampReady Plus. The upgrade is simulated; no payment is taken.
  final bool plus;

  /// Profile photo: a download URL or a base64 JPEG thumbnail.
  final String? photo;

  factory ProfileSettings.fromMap(Map<String, dynamic> map) => ProfileSettings(
    alertsEnabled: map['alertsEnabled'] as bool? ?? true,
    plus: map['plan'] == 'plus',
    photo: map['photo'] as String?,
  );

  @override
  List<Object?> get props => [alertsEnabled, plus, photo];
}

class ProfileRepository {
  ProfileRepository(this._firestore);

  final FirestoreService _firestore;

  Future<ProfileSettings> load(String uid) async =>
      ProfileSettings.fromMap(await _firestore.userSettings(uid));

  Future<void> setAlerts(String uid, bool enabled) =>
      _firestore.updateUserSettings(uid, {'alertsEnabled': enabled});

  Future<void> setPlus(String uid, bool plus) =>
      _firestore.updateUserSettings(uid, {'plan': plus ? 'plus' : 'free'});

  Future<void> setPhoto(String uid, String? photo) =>
      _firestore.updateUserSettings(uid, {'photo': photo});
}
