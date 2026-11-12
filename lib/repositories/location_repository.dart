import 'dart:async';

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
      final position = await _geo.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
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
