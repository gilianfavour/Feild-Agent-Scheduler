import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Result object returned by [LocationService.checkProximity].
class ProximityResult {
  final bool isWithinRadius;
  final double distanceMeters;
  final Position? position;
  final String? error;

  const ProximityResult({
    required this.isWithinRadius,
    required this.distanceMeters,
    this.position,
    this.error,
  });
}

/// Wraps Geolocator operations with permission handling and distance checks.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // ── Permission ─────────────────────────────────────────────────────────────

  /// Requests location permission and returns whether it was granted.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── Position ───────────────────────────────────────────────────────────────

  /// Returns the current device position.
  /// Throws [Exception] if the service is unavailable or permission denied.
  Future<Position> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) {
      throw Exception('Location permission not granted.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  // ── Proximity ──────────────────────────────────────────────────────────────

  /// Checks whether the device is within [radiusMeters] of [targetLat]/[targetLng].
  Future<ProximityResult> checkProximity({
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) async {
    try {
      final position = await getCurrentPosition();
      final distance = _haversineDistance(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );
      return ProximityResult(
        isWithinRadius: distance <= radiusMeters,
        distanceMeters: distance,
        position: position,
      );
    } catch (e) {
      return ProximityResult(
        isWithinRadius: false,
        distanceMeters: double.infinity,
        error: e.toString(),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Haversine formula – returns distance in metres between two coordinates.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // metres
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * (pi / 180);
}
