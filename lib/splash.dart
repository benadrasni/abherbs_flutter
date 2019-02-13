import 'dart:async';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/preferences.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class Splash extends StatefulWidget {
  final FirebaseUser currentUser;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, dynamic> notificationData;
  Splash(this.currentUser, this.onChangeLanguage, this.onBuyProduct, this.notificationData);

  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<Splash> {
  startTime() async {
    var _duration = new Duration(milliseconds: 300);
    var firstRoute = await _findFirstRoute();
    return new Timer(_duration, () {
      Navigator.pushReplacement(context, firstRoute);
    });
  }

  Future<MaterialPageRoute<dynamic>> _getFirstFilterRoute() {
    return Prefs.getBoolF(keyAlwaysMyRegion, false).then((alwaysMyRegionValue) {
      Map<String, String> filter = {};
      if (alwaysMyRegionValue) {
        return Prefs.getStringF(keyMyRegion, null).then((myRegionValue) {
          if (myRegionValue != null) {
            filter[filterDistribution] = myRegionValue;
          }
          return Future<MaterialPageRoute<dynamic>>(() {
            return getFirstFilterRoute(context, widget.currentUser, widget.onChangeLanguage, widget.onBuyProduct, filter);
          });
        });
      } else {
        return Future<MaterialPageRoute<dynamic>>(() {
          return getFirstFilterRoute(context, widget.currentUser, widget.onChangeLanguage, widget.onBuyProduct, filter);
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
        String action = widget.notificationData['action'];
        if (action == null) {
          return _getFirstFilterRoute();
        } else {
          switch (action) {
            case 'browse':
              String uri = widget.notificationData['uri'];
              if (uri != null) {
                launchURLF(uri);
                return _getFirstFilterRoute();
              }
              return _getFirstFilterRoute();
            case 'list':
              String count = widget.notificationData['count'];
              String path = widget.notificationData['path'];
              if (count != null && path != null) {
                return Future<MaterialPageRoute<dynamic>>(() {
                  return MaterialPageRoute(
                      builder: (context) => PlantList(widget.currentUser, widget.onChangeLanguage, widget.onBuyProduct, {}, count, path));
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
  Widget build(BuildContext context) {
    startTime();
    return Scaffold(
      body: Center(
        child: Image(
          image: AssetImage('res/images/home.png'),
        ),
      ),
    );
  }
}
