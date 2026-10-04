import 'package:abherbs_flutter/data/guide_results.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// This phone's position, for a photo taken now. Never asks for permission.
/// Null when location is not granted, switched off, or has no fix in time.
Future<({double latitude, double longitude})?> locateGuidePhone() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) return null;
    return (latitude: position.latitude, longitude: position.longitude);
  } catch (error) {
    debugPrint('guide phone position: $error');
    return null;
  }
}

/// Reads this phone's place and returns its floristic region code.
/// Throws [GuideLocationRefused] when location permission is denied. A phone
/// with no fix, indoors or on a simulator, would otherwise wait forever, so
/// both lookups time out.
Future<String?> locateGuideRegion() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const GuideLocationRefused();
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.low,
      timeLimit: Duration(seconds: 15),
    ),
  );
  final marks = await Geocoding()
      .placemarkFromCoordinates(position.latitude, position.longitude)
      .timeout(const Duration(seconds: 10));
  if (marks.isEmpty) return null;
  final place = marks.first;
  return guideRegionForPlace(
    countryCode: place.isoCountryCode,
    adminArea: place.administrativeArea,
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
