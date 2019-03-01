import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Upload {
  static bool uploadPaused = false;

  static void upload(FirebaseUser currentUser,
      Function() onObservationUpload, Function() onUploadFinish, Function() onUploadFail) {
    privateObservationsReference
        .child(currentUser.uid)
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .orderByChild(firebaseAttributeStatus)
        .equalTo(firebaseValuePrivate)
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null && snapshot.value.length > 0) {
        for(var key in snapshot.value.keys) {
          Observation observation = Observation.fromJson(key, snapshot.value[key]);
          print(observation.key);
        }
      }
    });
  }
}
