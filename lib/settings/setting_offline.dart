import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/offline.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class SettingOffline extends StatefulWidget {
  SettingOffline();

  @override
  _SettingOfflineState createState() => _SettingOfflineState();
}

class _SettingOfflineState extends State<SettingOffline> {
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
    setState(() {
      _plantsTotal = total;
      _plantsDownloaded = position;
    });
  }

  onDownloadFail() {
    setState(() {
      _downloadStatus = 3;
    });
  }

  onDownloadFinish() {
    setState(() {
      _downloadStatus = 2;
    });
  }

  @override
  void initState() {
    super.initState();

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
        _title = Text(S.of(context).offline_title, textAlign: TextAlign.center,);
        _content = Text(S.of(context).offline_download_message);
        _actions.add(FlatButton(
          child: Text(S.of(context).yes),
          onPressed: () {
            setState(() {
              _downloadStatus = 1;
            });
            Offline.download(this.onFamilyDownload, this.onPlantDownload, this.onDownloadFinish, this.onDownloadFail);
          },
        ));
        _actions.add(FlatButton(
          child: Text(S.of(context).no),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ));
        break;
      case 1:
        _title = Text(S.of(context).offline_download_progress, textAlign: TextAlign.center,);
        _content = LinearPercentIndicator(
          width: MediaQuery.of(context).size.width - 150,
          lineHeight: 20.0,
          percent: (_familiesDownloaded + _plantsDownloaded) / (_familiesTotal + _plantsTotal),
          backgroundColor: Theme.of(context).buttonColor,
          progressColor: Theme.of(context).accentColor,
        );
        break;
      case 2:
        _title = Text(S.of(context).offline_title, textAlign: TextAlign.center,);
        _content = Text(S.of(context).offline_download_success);
        _actions.add(FlatButton(
          child: Text(S.of(context).close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ));
        break;
      case 3:
        _title = Text(S.of(context).offline_title, textAlign: TextAlign.center, );
        _content = Text(S.of(context).offline_download_fail);
        _actions.add(FlatButton(
          child: Text(S.of(context).close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ));
        break;
    }

    return AlertDialog(
      title: _title,
      content: _content,
      actions: _actions,
    );
  }
}
