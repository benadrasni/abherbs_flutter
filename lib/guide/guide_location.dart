import 'package:abherbs_flutter/guide/guide_results.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Reads this phone's place and returns its floristic region code.
/// Throws [GuideLocationRefused] when location permission is denied.
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
    ),
  );
  final marks = await Geocoding().placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );
  if (marks.isEmpty) return null;
  final place = marks.first;
  return guideRegionForPlace(
    countryCode: place.isoCountryCode,
    adminArea: place.administrativeArea,
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
