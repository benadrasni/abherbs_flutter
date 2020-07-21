import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/observation_upload.dart';
import 'package:abherbs_flutter/observations/observation_view.dart';
import 'package:abherbs_flutter/observations/upload.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/purchase/subscription.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../main.dart';
import 'observation_logs.dart';

class Observations extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final bool isPublicOnly;
  Observations(this.currentUser, this.myLocale, this.onChangeLanguage, this.isPublicOnly);

  @override
  _ObservationsState createState() => _ObservationsState();
}

const Key _publicKey = Key('public');
const Key _privateKey = Key('private');

class _ObservationsState extends State<Observations> {
  FirebaseAnalytics _firebaseAnalytics;
  Key _key;
  bool _isPublic;
  Query _privateQuery;
  Query _publicQuery;
  Query _query;
  Future<int> _countUploadF;
  Future<ConnectivityResult> _connectivityResultF;
  bool _isUpload;
  int _observationsRemain;

  onObservationUpload() {
    if (mounted && _observationsRemain > 0) {
      setState(() {
        _observationsRemain--;
      });
    }
  }

  onObservationUploadFail() {}

  onUploadStart() {
    _logObservationUploadEvent('started');
    setState(() {
      _isUpload = true;
    });
  }

  onUploadFail() {
    _logObservationUploadEvent('failed');
    setState(() {
      _isUpload = false;
    });
  }

  onUploadFinish() {
    _logObservationUploadEvent('finished');
    setState(() {
      _isUpload = false;
    });
  }

  Future<void> _logObservationUploadEvent(String status) async {
    await _firebaseAnalytics.logEvent(name: 'observation_upload', parameters: {'uid': widget.currentUser.uid, 'status': status});
  }

  void _setIsPublic(bool isPublic) {
    if (Purchases.isSubscribed()) {
      setState(() {
        _isPublic = isPublic;
        _key = _isPublic ? _publicKey : _privateKey;
        _query = _isPublic ? _publicQuery : _privateQuery;
      });
    } else {
      subscriptionDialog(context, S.of(context).subscription, S.of(context).subscription_info).then((value) {
        if (value != null && value) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Subscription(), settings: RouteSettings(name: 'Subscription')),
          );
        }
      });
    }
  }

  Future<int> _setCountUpload() {
    if (Purchases.isSubscribed()) {
      privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsByDate).keepSynced(true);
      return privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsByDate).child(firebaseAttributeMock).set("mock").then((value) {
        _countUploadF = privateObservationsReference
            .child(widget.currentUser.uid)
            .child(firebaseObservationsByDate)
            .child(firebaseAttributeList)
            .orderByChild(firebaseAttributeStatus)
            .equalTo(firebaseValuePrivate)
            .once()
            .then((DataSnapshot snapshot) {
          setState(() {
            _observationsRemain = snapshot.value?.length ?? 0;
          });
          return snapshot.value?.length ?? 0;
        });
      });
    } else {
      return Future<int>(() {
        return 0;
      });
    }
  }

  void _startUpload() async {
    if (await _connectivityResultF == ConnectivityResult.wifi) {
      Upload.upload(widget.currentUser, this.onObservationUpload, this.onObservationUploadFail, this.onUploadStart, this.onUploadFinish, this.onUploadFail);
    }
  }

  Future<void> _uploadObservationDialog(int observationsToUpload) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ObservationUpload(widget.currentUser, observationsToUpload);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _key = _privateKey;
    _firebaseAnalytics = FirebaseAnalytics();
    initializeDateFormatting();
    _connectivityResultF = Connectivity().checkConnectivity();

    _publicQuery = publicObservationsReference.child(firebaseObservationsByDate).child(firebaseAttributeList).orderByChild(firebaseAttributeOrder);
    if (widget.isPublicOnly) {
      _isPublic = true;
      _query = _publicQuery;
    } else {
      _isPublic = false;
      _privateQuery = privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsByDate).child(firebaseAttributeList).orderByChild(firebaseAttributeOrder);
      _query = _privateQuery;
    }

    _isUpload = false;
    _observationsRemain = 0;
    _countUploadF = _setCountUpload();
    _startUpload();
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
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
              _isUpload
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
                    builder: (context) => ObservationLogs(widget.currentUser, Localizations.localeOf(context), widget.onChangeLanguage), settings: RouteSettings(name: 'ObservationLogs')),
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
            child: Text(S.of(context).observation_empty, style: TextStyle(fontSize: 20.0)),
          ),
          query: _query,
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
            Observation observation = Observation.fromJson(snapshot.key, snapshot.value);
            return ObservationView(widget.currentUser, myLocale, widget.onChangeLanguage, observation);
          }),
      floatingActionButton: FutureBuilder<List<dynamic>>(
          future: Future.wait([_countUploadF, _connectivityResultF]),
          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                if (snapshot.data[0] > 0) {
                  return Container(
                    height: 70.0,
                    width: 70.0,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: FloatingActionButton(
                        onPressed: () {
                          snapshot.data[1] == ConnectivityResult.wifi
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ObservationLogs(widget.currentUser, Localizations.localeOf(context), widget.onChangeLanguage),
                                      settings: RouteSettings(name: 'ObservationLogs')),
                                )
                              : _uploadObservationDialog(snapshot.data[0]).then((value) {
                                  _setCountUpload();
                                });
                        },
                        child: Icon(snapshot.data[1] == ConnectivityResult.wifi ? Icons.list : Icons.cloud_upload),
                      ),
                    ),
                  );
                } else if (Purchases.isSubscribed()) {
                  return Container(
                    height: 70.0,
                    width: 70.0,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ObservationLogs(widget.currentUser, Localizations.localeOf(context), widget.onChangeLanguage),
                                settings: RouteSettings(name: 'ObservationLogs')),
                          );
                        },
                        child: Icon(Icons.list),
                      ),
                    ),
                  );
                }
                return Container(
                  width: 0.0,
                  height: 0.0,
                );
              default:
                return Container(
                  width: 0.0,
                  height: 0.0,
                );
            }
          }),
    );
  }
}
