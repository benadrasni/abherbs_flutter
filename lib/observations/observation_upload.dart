import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/upload.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ObservationUpload extends StatefulWidget {
  final int observationsToUpload;
  ObservationUpload(this.observationsToUpload);

  @override
  _ObservationUploadState createState() => _ObservationUploadState();
}

class _ObservationUploadState extends State<ObservationUpload> {
  int _uploadStatus = 0; // 0: initial, 1: uploading,  2: successful, 3: failed
  late int _observationsRemain;

  onObservationUpload() {
    if (mounted && _observationsRemain > 0) {
      setState(() {
        _observationsRemain = Upload.count;
      });
    }
  }

  onObservationUploadFail() {
  }

  onUploadStart() {
  }

  onUploadFail() {
    if (mounted) {
      setState(() {
        _uploadStatus = 3;
      });
    }
  }

  onUploadFinish() {
    if (mounted) {
      setState(() {
        _uploadStatus = 2;
      });
    }
  }

  @override
  void initState() {
    super.initState();

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
        _actions.add(TextButton(
          child: Text(S.of(context).yes.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Upload.uploadPaused = false;
            setState(() {
              _uploadStatus = 1;
            });
            Upload.upload(this.onObservationUpload, this.onObservationUploadFail, this.onUploadStart, this.onUploadFinish, this.onUploadFail);
          },
        ));
        _actions.add(TextButton(
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
        _content = Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: LinearPercentIndicator(
            lineHeight: 20.0,
            percent: (widget.observationsToUpload - _observationsRemain) / widget.observationsToUpload,
            progressColor: Theme.of(context).primaryColor,
          ),
        );
        _actions.add(TextButton(
          child: Text(S.of(context).pause.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
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
        _actions.add(TextButton(
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
        _actions.add(TextButton(
          child: Text(S.of(context).close.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ));
        break;
    }

    return PopScope(
        child: AlertDialog(
          title: _title,
          content: _content,
          actions: _actions,
        ));
  }
}
