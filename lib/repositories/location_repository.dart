import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  unknown,
  locating,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

class LocationResult {
  const LocationResult(this.status, {this.latitude, this.longitude});
  final LocationStatus status;
  final double? latitude;
  final double? longitude;
}

/// GPS through geolocator: service check, permission, current position.
class LocationRepository {
  LocationRepository({GeolocatorPlatform? geolocator})
    : _geo = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geo;

  static const _metersPerMile = 1609.344;

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// On Android the plain location manager is used, so GPS works even
  /// when the user declines Google's "Location Accuracy" prompt.
  LocationSettings get _settings => _android
      ? AndroidSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
          forceLocationManager: true,
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        );

  Future<LocationResult> currentPosition() async {
    try {
      if (!await _geo.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }
      var permission = await _geo.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geo.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      Position? position;
      try {
        position = await _geo.getCurrentPosition(locationSettings: _settings);
      } on TimeoutException {
        position = await _geo.getLastKnownPosition(
          forceLocationManager: _android,
        );
      }
      if (position == null) {
        return const LocationResult(LocationStatus.unavailable);
      }
      return LocationResult(
        LocationStatus.granted,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on PermissionDeniedException {
      return const LocationResult(LocationStatus.denied);
    } on LocationServiceDisabledException {
      return const LocationResult(LocationStatus.serviceDisabled);
    } catch (_) {
      return const LocationResult(LocationStatus.unavailable);
    }
  }

  double milesBetween(double lat1, double lng1, double lat2, double lng2) =>
      _geo.distanceBetween(lat1, lng1, lat2, lng2) / _metersPerMile;

  Future<bool> openAppSettings() => _geo.openAppSettings();

  Future<bool> openLocationSettings() => _geo.openLocationSettings();
}
