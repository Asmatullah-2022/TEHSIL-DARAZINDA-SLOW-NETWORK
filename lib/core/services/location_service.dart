import 'package:geolocator/geolocator.dart';

sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  const LocationSuccess(this.position);
  final Position position;
}

/// Location services (GPS) are turned off at the OS level.
class LocationServiceDisabled extends LocationResult {
  const LocationServiceDisabled();
}

/// User denied the location permission (once, or permanently).
class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied({required this.isPermanent});
  final bool isPermanent;
}

class LocationTimedOut extends LocationResult {
  const LocationTimedOut();
}

/// Wraps Geolocator with explicit, user-legible failure states instead
/// of throwing — callers (e.g. the network test screen) must show
/// clear guidance for each state rather than crashing or silently
/// substituting a fake location.
class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationServiceDisabled();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationPermissionDenied(isPermanent: false);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionDenied(isPermanent: true);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationSuccess(position);
    } on Exception {
      return const LocationTimedOut();
    }
  }
}
