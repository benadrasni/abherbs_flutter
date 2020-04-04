import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/upload.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ObservationUpload extends StatefulWidget {
  final FirebaseUser currentUser;
  final int observationsToUpload;
  ObservationUpload(this.currentUser, this.observationsToUpload);

  @override
  _ObservationUploadState createState() => _ObservationUploadState();
}

class _ObservationUploadState extends State<ObservationUpload> {
  FirebaseAnalytics _firebaseAnalytics;
  int _observationsRemain;
  int _uploadStatus; // 0: initial, 1: uploading,  2: successful, 3: failed

  onObservationUpload() {
    if (mounted && _observationsRemain > 0) {
      setState(() {
        _observationsRemain--;
      });
    }
  }

  onUploadFail() {
    _logObservationUploadEvent('failed');
    if (mounted) {
      setState(() {
        _uploadStatus = 3;
      });
    }
  }

  onUploadFinish() {
    _logObservationUploadEvent('finished');
    if (mounted) {
      setState(() {
        _uploadStatus = 2;
      });
    }
  }

  Future<void> _logObservationUploadEvent(String status) async {
    await _firebaseAnalytics.logEvent(name: 'observation_upload', parameters: {
      'status': status
    });
  }

  @override
  void initState() {
    super.initState();
    _firebaseAnalytics = FirebaseAnalytics();

    _uploadStatus = 0;
    _observationsRemain = widget.observationsToUpload;
  }

  @override
  Widget build(BuildContext context) {
    var _actions = <Widget>[];
    var _content;
    var _title;
    switch (_uploadStatus) {
      case 0:
        _title = Text(
          S.of(context).observation_upload_title
        );
        _content = Text(S.of(context).observation_upload_message(_observationsRemain.toString()));
        _actions.add(FlatButton(
          child: Text(S.of(context).yes.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            _logObservationUploadEvent('started');
            Upload.uploadPaused = false;
            setState(() {
              _uploadStatus = 1;
            });
            Upload.upload(widget.currentUser, this.onObservationUpload, this.onUploadFinish, this.onUploadFail);
          },
        ));
        _actions.add(FlatButton(
          child: Text(S.of(context).no.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ));
        break;
      case 1:
        _title = Text(
          S.of(context).observation_upload_progress,
          textAlign: TextAlign.center,
        );
        _content = LinearPercentIndicator(
          width: MediaQuery.of(context).size.width - 150,
          lineHeight: 20.0,
          percent: (widget.observationsToUpload - _observationsRemain) / widget.observationsToUpload,
          backgroundColor: Theme.of(context).buttonColor,
          progressColor: Theme.of(context).accentColor,
        );
        _actions.add(FlatButton(
          child: Text(S.of(context).pause.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            _logObservationUploadEvent('paused');
            Upload.uploadPaused = true;
            Navigator.of(context).pop();
          },
        ));
        break;
      case 2:
        _title = Text(
          S.of(context).observation_upload_title
        );
        _content = Text(S.of(context).observation_upload_success);
        _actions.add(FlatButton(
          child: Text(S.of(context).close.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ));
        break;
      case 3:
        _title = Text(
          S.of(context).observation_upload_title,
        );
        _content = Text(S.of(context).observation_upload_fail);
        _actions.add(FlatButton(
          child: Text(S.of(context).close.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ));
        break;
    }

    return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: _title,
          content: _content,
          actions: _actions,
        ));
  }
}
