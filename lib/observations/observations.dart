import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/observation_upload.dart';
import 'package:abherbs_flutter/observations/observation_view.dart';
import 'package:abherbs_flutter/observations/upload.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'observation_logs.dart';

class Observations extends StatefulWidget {
  final Locale myLocale;
  final bool isPublicOnly;
  Observations(this.myLocale, this.isPublicOnly);

  @override
  _ObservationsState createState() => _ObservationsState();
}

const Key _publicKey = Key('public');
const Key _privateKey = Key('private');

class _ObservationsState extends State<Observations> {
  Key _key = _privateKey;
  late bool _isPublic;
  late Query _privateQuery;
  late Query _publicQuery;
  late Query _query;
  late Future<List<ConnectivityResult>> _connectivityResultF;
  int _observationsRemain = 0;

  onObservationUpload() {
    if (mounted) {
      setState(() {
        _observationsRemain = Upload.count;
      });
    }
  }

  onObservationUploadFail() {}
  onUploadStart() {}
  onUploadFinish() {
    if (mounted) {
      setState(() {
        _observationsRemain = Upload.count;
      });
    }
  }

  onUploadFail() {
    if (mounted) {
      setState(() {
        _observationsRemain = Upload.count;
      });
    }
  }

  void _setIsPublic(bool isPublic) {
    if (Purchases.isSubscribed()) {
      setState(() {
        _isPublic = isPublic;
        _key = _isPublic ? _publicKey : _privateKey;
        _query = _isPublic ? _publicQuery : _privateQuery;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ObservationLogs(Localizations.localeOf(context), 1),
            settings: RouteSettings(name: 'ObservationLogs')),
      );
    }
  }

  void _setCountUpload() {
    if (Purchases.isSubscribed()) {
      privateObservationsReference
          .child(Auth.appUser!.uid)
          .child(firebaseObservationsByDate)
          .keepSynced(true);
      privateObservationsReference
          .child(Auth.appUser!.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeMock)
          .set("mock")
          .then((value) {
        privateObservationsReference
            .child(Auth.appUser!.uid)
            .child(firebaseObservationsByDate)
            .child(firebaseAttributeList)
            .orderByChild(firebaseAttributeStatus)
            .equalTo(firebaseValuePrivate)
            .once()
            .then((event) {
          setState(() {
            Map result = event.snapshot.value != null ? event.snapshot.value as Map : {};
            _observationsRemain = result.length;
          });
        });
      });
    }
  }

  void _startUpload() async {
    if ((await _connectivityResultF).contains(ConnectivityResult.wifi)) {
      Upload.upload(this.onObservationUpload, this.onObservationUploadFail,
          this.onUploadStart, this.onUploadFinish, this.onUploadFail);
    }
  }

  Future<void> _uploadObservationDialog(int observationsToUpload) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ObservationUpload(observationsToUpload);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _connectivityResultF = Connectivity().checkConnectivity();

    _publicQuery = publicObservationsReference
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .orderByChild(firebaseAttributeOrder);
    if (widget.isPublicOnly) {
      _isPublic = true;
      _query = _publicQuery;
    } else {
      _isPublic = false;
      _privateQuery = privateObservationsReference
          .child(Auth.appUser!.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .orderByChild(firebaseAttributeOrder);
      _query = _privateQuery;
    }

    _setCountUpload();
    _startUpload();
  }

  @override
  Widget build(BuildContext context) {
    var myLocale = Localizations.localeOf(context);

    List<Widget> appBarItems = [];
    appBarItems.add(Text(S.of(context).observations));
    appBarItems.add(_observationsRemain > 0
        ? GestureDetector(
            child: Stack(alignment: AlignmentDirectional.center, children: [
              Container(
                  child: FittedBox(
                fit: BoxFit.fill,
                child: Text(_observationsRemain.toString()),
              )),
              Upload.uploadStarted
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Container(
                      width: 0.0,
                      height: 0.0,
                    )
            ]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ObservationLogs(Localizations.localeOf(context), 2),
                    settings: RouteSettings(name: 'ObservationLogs')),
              );
            },
          )
        : Container(
            width: 0.0,
            height: 0.0,
          ));
    if (widget.isPublicOnly) {
      appBarItems.add(Icon(Icons.people));
    } else {
      appBarItems.add(Row(
        children: [
          Icon(Icons.person),
          Switch(
            value: _isPublic,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.white,
            onChanged: (bool value) {
              _setIsPublic(value);
            },
          ),
          Icon(Icons.people),
        ],
      ));
    }

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: appBarItems,
        ),
      ),
      body: MyFirebaseAnimatedList(
          defaultChild: Center(child: CircularProgressIndicator()),
          emptyChild: Container(
            padding: EdgeInsets.all(5.0),
            alignment: Alignment.center,
            child: Text(S.of(context).observation_empty,
                style: TextStyle(fontSize: 20.0)),
          ),
          query: _query,
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation,
              int index) {
            Observation observation =
                Observation.fromJson(snapshot.key, snapshot.value as Map);
            return ObservationView(myLocale, observation);
          }),
      floatingActionButton: FutureBuilder<List<ConnectivityResult>>(
          future: _connectivityResultF,
          builder: (BuildContext context,
              AsyncSnapshot<List<ConnectivityResult>> snapshot) {
            Widget result = Container(width: 0.0, height: 0.0);
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                if (_observationsRemain > 0) {
                  result = Container(
                    height: 70.0,
                    width: 70.0,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: FloatingActionButton(
                        onPressed: () {
                          snapshot.data!.contains(ConnectivityResult.wifi)
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ObservationLogs(
                                          Localizations.localeOf(context), 0),
                                      settings: RouteSettings(
                                          name: 'ObservationLogs')),
                                )
                              : _uploadObservationDialog(_observationsRemain)
                                  .then((value) {
                                  _setCountUpload();
                                });
                        },
                        child: Icon(
                            snapshot.data!.contains(ConnectivityResult.wifi)
                                ? Icons.list
                                : Icons.cloud_upload),
                      ),
                    ),
                  );
                } else {
                  result = Container(
                    height: 70.0,
                    width: 70.0,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ObservationLogs(
                                    Localizations.localeOf(context), 0),
                                settings:
                                    RouteSettings(name: 'ObservationLogs')),
                          );
                        },
                        child: Icon(Icons.list),
                      ),
                    ),
                  );
                }
                break;
              default:
            }
            return result;
          }),
    );
  }
}
