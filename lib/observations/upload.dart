import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class Upload {
  static bool uploadPaused = false;
  static bool uploadStarted = false;
  static int count = 0;
  static Function()? _onUploadStart;
  static Function()? _onUploadFinish;
  static Function()? _onUploadFail;
  static Function()? _onObservationUpload;
  static Function()? _onObservationUploadFail;
  static firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instanceFor(bucket: storageBucket);
  static FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;

  static Future<void> _logObservationUploadEvent(String uid, String status) async {
    await _firebaseAnalytics.logEvent(name: 'observation_upload', parameters: {'uid': uid, 'status': status});
  }

  static Future<void> upload(Function() onObservationUpload, Function() onObservationUploadFail, Function() onUploadStart, Function() onUploadFinish, Function() onUploadFail) async {
    _onObservationUpload = onObservationUpload;
    _onObservationUploadFail = onObservationUploadFail;
    _onUploadStart = onUploadStart;
    _onUploadFinish = onUploadFinish;
    _onUploadFail = onUploadFail;

    if (uploadStarted) return;

    uploadStarted = true;
    privateObservationsReference
        .child(Auth.appUser!.uid)
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .orderByChild(firebaseAttributeStatus)
        .equalTo(firebaseValuePrivate)
        .once()
        .then((event) async {
      count = (event.snapshot.value as Map).length;
      if (count > 0) {
        _onUploadStart!();
        _logObservationUploadEvent(Auth.appUser!.uid, 'started');
        var date = DateTime.now();
        await logsObservationsReference.child(Auth.appUser!.uid).child(date.millisecondsSinceEpoch.toString()).child(firebaseAttributeTime).set(-1 * date.millisecondsSinceEpoch);
        for (var key in (event.snapshot.value as Map).keys) {
          if (uploadPaused) {
            _logObservationUploadEvent(Auth.appUser!.uid, 'paused');
            break;
          }
          Observation observation = Observation.fromJson(key, (event.snapshot.value as Map)[key]);
          if (await _uploadObservation(observation)) {
            await logsObservationsReference.child(Auth.appUser!.uid).child(date.millisecondsSinceEpoch.toString()).child(observation.id!).child(firebaseAttributeStatus).set(firebaseValueSuccess);
            count--;
            _onObservationUpload!();
          } else {
            await logsObservationsReference.child(Auth.appUser!.uid).child(date.millisecondsSinceEpoch.toString()).child(observation.id!).child(firebaseAttributeStatus).set(firebaseValueFailure);
            _onObservationUploadFail!();
          }
        }
        _logObservationUploadEvent(Auth.appUser!.uid, 'finished');
        _onUploadFinish!();
      }
      uploadStarted = false;
      uploadPaused = false;
    }).catchError((error) {
      _logObservationUploadEvent(Auth.appUser!.uid, 'failed');
      uploadStarted = false;
      uploadPaused = false;
      _onUploadFail!();
    });
  }

  static Future<bool> _uploadObservation(Observation observation) async {
    for (var path in observation.photoPaths) {
      if (!await _uploadFile(path)) {
        return false;
      }
    }

    observation.status = firebaseValueReview;

    // save to public
    await publicObservationsReference.child(firebaseObservationsByDate).child(firebaseAttributeList).child(observation.id!).set(observation.toJson());
    await publicObservationsReference.child(firebaseObservationsByPlant).child(observation.plant).child(firebaseAttributeList).child(observation.id!).set(observation.toJson());

    // update private
    await privateObservationsReference
        .child(Auth.appUser!.uid)
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .child(observation.id!)
        .child(firebaseAttributeStatus)
        .set(firebaseValuePublic);
    await privateObservationsReference
        .child(Auth.appUser!.uid)
        .child(firebaseObservationsByPlant)
        .child(observation.plant)
        .child(firebaseAttributeList)
        .child(observation.id!)
        .child(firebaseAttributeStatus)
        .set(firebaseValuePublic);
    return true;
  }

  static Future<bool> _uploadFile(String path) async {
    File? file = await Offline.getLocalFile(path);
    final firebase_storage.Reference ref = _storage.ref().child(path);
    if (file != null) {
      return await ref.putFile(file).then((firebase_storage.TaskSnapshot snapshot) {
        return true;
      }).catchError((error) {
        return false;
      });
    }
    return false;
  }
}
