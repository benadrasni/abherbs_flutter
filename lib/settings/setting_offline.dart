import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';


class SettingOffline extends StatefulWidget {
  final void Function(bool) onDownloadFinished;
  SettingOffline(this.onDownloadFinished);

  @override
  _SettingOfflineState createState() => _SettingOfflineState();
}

class _SettingOfflineState extends State<SettingOffline> {
  FirebaseAnalytics _firebaseAnalytics;
  int _familiesTotal;
  int _familiesDownloaded;
  int _plantsTotal;
  int _plantsDownloaded;
  int _downloadStatus; // 0: initial, 1: downloading,  2: successful, 3: failed

  onFamilyDownload(int position, int total) {
    setState(() {
      _familiesTotal = total;
      _familiesDownloaded = position;
    });
  }

  onPlantDownload(int position, int total) {
    if (mounted) {
      setState(() {
        _plantsTotal = total;
        _plantsDownloaded = position;
      });
    }
  }

  onDownloadFail() {
    _logOfflineDownloadEvent('failed');
    if (mounted) {
      setState(() {
        _downloadStatus = 3;
      });
    }
  }

  onDownloadFinish() {
    _logOfflineDownloadEvent('finished');
    if (mounted) {
      setState(() {
        _downloadStatus = 2;
      });
    }
  }

  Future<void> _logOfflineDownloadEvent(String status) async {
    await _firebaseAnalytics.logEvent(name: 'offline_download', parameters: {
      'status': status
    });
  }

  @override
  void initState() {
    super.initState();
    _firebaseAnalytics = FirebaseAnalytics();

    _downloadStatus = 0;
    _familiesDownloaded = 0;
    _plantsDownloaded = 0;
    _familiesTotal = 1000;
    _plantsTotal = 1000;
  }

  @override
  Widget build(BuildContext context) {
    var _actions = <Widget>[];
    var _content;
    var _title;
    switch (_downloadStatus) {
      case 0:
        _title = Text(
          S.of(context).offline_title
        );
        _content = Text(S.of(context).offline_download_message);
        _actions.add(FlatButton(
          child: Text(S.of(context).yes.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            _logOfflineDownloadEvent('started');
            Offline.downloadPaused = false;
            setState(() {
              _downloadStatus = 1;
            });
            Offline.download(this.onFamilyDownload, this.onPlantDownload, this.onDownloadFinish, this.onDownloadFail);
          },
        ));
        _actions.add(FlatButton(
          child: Text(S.of(context).no.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDownloadFinished(false);
          },
        ));
        break;
      case 1:
        _title = Text(
          S.of(context).offline_download_progress,
          textAlign: TextAlign.center,
        );
        _content = LinearPercentIndicator(
          width: MediaQuery.of(context).size.width - 150,
          lineHeight: 20.0,
          percent: (_familiesDownloaded + _plantsDownloaded) / (_familiesTotal + _plantsTotal),
          backgroundColor: Theme.of(context).buttonColor,
          progressColor: Theme.of(context).accentColor,
        );
        _actions.add(FlatButton(
          child: Text(S.of(context).pause.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            _logOfflineDownloadEvent('paused');
            Offline.downloadPaused = true;
            Navigator.of(context).pop();
            widget.onDownloadFinished(false);
          },
        ));
        break;
      case 2:
        _title = Text(
          S.of(context).offline_title
        );
        _content = Text(S.of(context).offline_download_success);
        _actions.add(FlatButton(
          child: Text(S.of(context).close.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDownloadFinished(true);
          },
        ));
        break;
      case 3:
        _title = Text(
          S.of(context).offline_title,
        );
        _content = Text(S.of(context).offline_download_fail);
        _actions.add(FlatButton(
          child: Text(S.of(context).close.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDownloadFinished(false);
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
