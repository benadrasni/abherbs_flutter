import 'package:abherbs_flutter/seen/observation.dart';
import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/seen/guide_private_photos.dart';
import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/offline/offline.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';

/// Publishes one confirmed find for review. The note stays on the private
/// row. Returns false when there is no account, no photo, or the write fails.
Future<bool> shareGuideFind(String id) async {
  try {
    final user = Auth.appUser;
    if (user == null || id.isEmpty) return false;
    final root = privateObservationsReference.child(user.uid);
    final dateRef = root
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(id);
    final event = await dateRef.once();
    final raw = event.snapshot.value;
    if (raw is! Map) return false;
    final observation =
        Observation.fromJson(id, Map<dynamic, dynamic>.from(raw));
    observation.photoPaths = _photoPaths(raw[observationPhotoPaths]);
    if (!observation.confirmed || observation.plant.isEmpty) return false;
    if (observation.photoPaths.isEmpty) return false;
    for (final path in observation.photoPaths) {
      if (path is! String || !await _uploadPhoto(path)) return false;
    }
    observation.note = '';
    observation.candidates = [];
    observation.status = firebaseValueReview;
    final json = observation.toJson();
    final plant = observation.plant;
    await publicObservationsReference
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(observation.id)
        .set(json);
    await publicObservationsReference
        .child(firebaseObservationsByPlant)
        .child(plant)
        .child(firebaseAttributeList)
        .child(observation.id)
        .set(json);
    final patch = {observationStatus: firebaseValueReview};
    await dateRef.update(patch);
    await _patchPrivatePlant(root, plant, observation.id, patch);
    return true;
  } catch (error) {
    debugPrint('guide seen share: $error');
    return false;
  }
}

/// Removes a find from Seen, including its photo on this phone and in
/// private storage. A find that was sent (in review, shared, or not
/// accepted) also leaves the public record and its public photo.
Future<bool> deleteGuideSeenFind({
  required String id,
  required String plant,
  required GuideSeenShare share,
}) async {
  try {
    if (share != GuideSeenShare.none) {
      final user = Auth.appUser;
      if (user == null || id.isEmpty) return false;
      final event = await privateObservationsReference
          .child(user.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(id)
          .once();
      final raw = event.snapshot.value;
      if (raw is Map) {
        await _deletePublicPhotos(_photoPaths(raw[observationPhotoPaths]));
      }
      await publicObservationsReference
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(id)
          .remove();
      await _removePublicPlant(plant, id);
    }
    await deleteGuideCameraFind(id: id, plant: plant);
    return true;
  } catch (error) {
    debugPrint('guide seen delete: $error');
    return false;
  }
}

/// Removes a find from Sightings. The private row stays, marked private.
Future<bool> withdrawGuideFind({
  required String id,
  required String plant,
}) async {
  try {
    final user = Auth.appUser;
    if (user == null || id.isEmpty) return false;
    await publicObservationsReference
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(id)
        .remove();
    await _removePublicPlant(plant, id);
    final patch = {observationStatus: observationStatusPrivate};
    final root = privateObservationsReference.child(user.uid);
    await root
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(id)
        .update(patch);
    await _patchPrivatePlant(root, plant, id, patch);
    return true;
  } catch (error) {
    debugPrint('guide seen withdraw: $error');
    return false;
  }
}

/// Camera finds use a sanitized plant key. Manual finds use the Latin name.
/// For an ordinary binomial the two are the same.
Set<String> _plantKeys(String plant) {
  return {
    if (plant.isNotEmpty) plant,
    if (guideObservationPlantKey(plant).isNotEmpty)
      guideObservationPlantKey(plant),
  };
}

Future<void> _patchPrivatePlant(
  DatabaseReference root,
  String plant,
  String id,
  Map<String, Object> patch,
) async {
  for (final key in _plantKeys(plant)) {
    final ref = root
        .child(firebaseObservationsByPlant)
        .child(key)
        .child(firebaseAttributeList)
        .child(id);
    final event = await ref.once();
    if (event.snapshot.exists) await ref.update(patch);
  }
}

Future<void> _removePublicPlant(String plant, String id) async {
  for (final key in _plantKeys(plant)) {
    await publicObservationsReference
        .child(firebaseObservationsByPlant)
        .child(key)
        .child(firebaseAttributeList)
        .child(id)
        .remove();
  }
}

Future<void> _deletePublicPhotos(List<String> paths) async {
  for (final path in paths) {
    if (!path.startsWith(storageObservations)) continue;
    try {
      await firebase_storage.FirebaseStorage.instanceFor(bucket: storageBucket)
          .ref()
          .child(path)
          .delete();
    } on firebase_storage.FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        debugPrint('guide seen public photo $path: $error');
      }
    } catch (error) {
      debugPrint('guide seen public photo $path: $error');
    }
  }
}

List<String> _photoPaths(dynamic raw) {
  final paths = <String>[];
  void add(dynamic value) {
    if (value is String && value.isNotEmpty) paths.add(value);
  }

  if (raw is List) {
    for (final item in raw) {
      add(item);
    }
  } else if (raw is Map) {
    final keys = raw.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      add(raw[key]);
    }
  }
  return paths;
}

Future<bool> _uploadPhoto(String path) async {
  var file = await Offline.getLocalFile(path);
  file ??= await fetchGuidePrivatePhoto(path);
  if (file == null) return _publicObjectExists(path);
  try {
    final ref =
        firebase_storage.FirebaseStorage.instanceFor(bucket: storageBucket)
            .ref()
            .child(path);
    await ref.putFile(file);
    return true;
  } catch (error) {
    debugPrint('guide seen photo $path: $error');
    return false;
  }
}

/// A photo already published has no local file on a second phone. Sharing
/// again can keep that object. A path outside Storage is not one.
Future<bool> _publicObjectExists(String path) async {
  if (!path.startsWith(storageObservations)) return false;
  try {
    await firebase_storage.FirebaseStorage.instanceFor(bucket: storageBucket)
        .ref()
        .child(path)
        .getMetadata();
    return true;
  } catch (error) {
    debugPrint('guide seen photo $path: $error');
    return false;
  }
}
