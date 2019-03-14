import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Upload {
  static bool uploadPaused = false;
  static bool _uploadStarted = false;
  static FirebaseStorage storage = FirebaseStorage(storageBucket: storageBucket);

  static Future<void> upload(FirebaseUser currentUser,
      Function() onObservationUpload, Function() onUploadFinish, Function() onUploadFail) async {
    if (!_uploadStarted) {
      _uploadStarted = true;
      privateObservationsReference
          .child(currentUser.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .orderByChild(firebaseAttributeStatus)
          .equalTo(firebaseValuePrivate)
          .once()
          .then((DataSnapshot snapshot) async {
        if (snapshot.value != null && snapshot.value.length > 0) {
          for (var key in snapshot.value.keys) {
            if (uploadPaused) {
              break;
            }
            Observation observation = Observation.fromJson(key, snapshot.value[key]);
            if (await _uploadObservation(currentUser, observation)) {
              onObservationUpload();
            } else {
              onUploadFail();
              _uploadStarted = false;
              uploadPaused = false;
              return;
            }
          }
          onUploadFinish();
          _uploadStarted = false;
          uploadPaused = false;
        }
      }).catchError((error) {
        onUploadFail();
        _uploadStarted = false;
        uploadPaused = false;
      });
    }
  }

  static Future<bool> _uploadObservation(FirebaseUser currentUser, Observation observation) async {
    for(var path in observation.photoPaths) {
      if (!await _uploadFile(path)) {
        return false;
      }
    }

    observation.status = firebaseValueReview;

    // save to public
    await publicObservationsReference
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(observation.date.millisecondsSinceEpoch.toString())
        .set(observation.toJson());
    await publicObservationsReference
        .child(firebaseObservationsByPlant)
        .child(observation.plant)
        .child(firebaseAttributeList)
        .child(observation.date.millisecondsSinceEpoch.toString())
        .set(observation.toJson());

    // update private
    await privateObservationsReference
        .child(currentUser.uid)
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(observation.id)
        .child(firebaseAttributeStatus).set(firebaseValuePublic);
    await privateObservationsReference
        .child(currentUser.uid)
        .child(firebaseObservationsByPlant)
        .child(observation.plant)
        .child(firebaseAttributeList)
        .child(observation.id)
        .child(firebaseAttributeStatus).set(firebaseValuePublic);
    return true;
  }

  static Future<bool> _uploadFile(String path) async {
    File file = await Offline.getLocalFile(path);
    final StorageReference ref = storage.ref().child(path);
    final StorageUploadTask uploadTask = ref.putFile(file);

    return await uploadTask.onComplete.then((StorageTaskSnapshot snapshot) {
      return true;
    }).catchError((error) {
      return false;
    });
  }
}
