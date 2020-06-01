import 'dart:async';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';

class Splash extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, dynamic> notificationData;
  Splash(this.onChangeLanguage, this.notificationData);

  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<Splash> {

  _redirect(BuildContext context) async {
    var _duration = Duration(milliseconds: timer);
    var firstRoute = await _findFirstRoute();
    return Timer(_duration, () {
      if (mounted) {
        Navigator.pushReplacement(context, firstRoute);
      }
    });
  }

  Future<MaterialPageRoute<dynamic>> _getFirstFilterRoute([MaterialPageRoute<dynamic> redirect]) {
    return Prefs.getBoolF(keyAlwaysMyRegion, false).then((alwaysMyRegionValue) {
      Map<String, String> filter = {};
      if (alwaysMyRegionValue) {
        return Prefs.getStringF(keyMyRegion, null).then((myRegionValue) {
          if (myRegionValue != null) {
            filter[filterDistribution] = myRegionValue;
          }
          return Future<MaterialPageRoute<dynamic>>(() {
            return getFirstFilterRoute(context, widget.onChangeLanguage, filter, redirect);
          });
        });
      } else {
        return Future<MaterialPageRoute<dynamic>>(() {
          return getFirstFilterRoute(context, widget.onChangeLanguage, filter, redirect);
        });
      }
    });
  }

  Future<MaterialPageRoute<dynamic>> _findFirstRoute() {
    return Prefs.getStringListF(keyMyFilter, filterAttributes).then((myFilter) {
      Preferences.myFilterAttributes = myFilter;
      if (widget.notificationData == null) {
        return _getFirstFilterRoute();
      } else {
        String action = widget.notificationData[notificationAttributeAction];
        if (action == null) {
          return _getFirstFilterRoute();
        } else {
          switch (action) {
            case notificationAttributeActionBrowse:
              String uri = widget.notificationData[notificationAttributeUri];
              if (uri != null) {
                launchURLF(uri);
                return _getFirstFilterRoute();
              }
              return _getFirstFilterRoute();
            case notificationAttributeActionList:
              String path = widget.notificationData[notificationAttributePath];
              if (path != null) {
                rootReference.child(path).keepSynced(true);
                rootReference.child(firebasePlantHeaders).keepSynced(true);
                return rootReference.child(path).once().then((DataSnapshot snapshot) {
                  var result = snapshot.value??[];
                  int length = result is List ? result.fold(0, (t, value) => t + (value == null ? 0 : 1) ) : result.values.length;
                  if (length == 0) {
                    rootReference.child(path).child("refreshMock").set("mock").catchError((error) {
                      FlutterCrashlytics().log("0-length custom list");
                    });
                  }
                  return _getFirstFilterRoute(MaterialPageRoute(
                      builder: (context) => PlantList(widget.onChangeLanguage, {}, '', rootReference.child(path)),
                      settings: RouteSettings(name: 'PlantList')));
                });
              }
              return _getFirstFilterRoute();
            default:
              return _getFirstFilterRoute();
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _redirect(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image(
          image: AssetImage('res/images/home.png'),
        ),
      ),
    );
  }
}
