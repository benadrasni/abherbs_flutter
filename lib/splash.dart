import 'dart:async';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class Splash extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, dynamic> notificationData;
  Splash(this.onChangeLanguage, this.onBuyProduct, this.notificationData);

  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<Splash> {

  _redirect(BuildContext context) async {
    var firstRoute = await _findFirstRoute();
    Navigator.pushReplacement(context, firstRoute);
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
            return getFirstFilterRoute(context, widget.onChangeLanguage, widget.onBuyProduct, filter, redirect);
          });
        });
      } else {
        return Future<MaterialPageRoute<dynamic>>(() {
          return getFirstFilterRoute(context, widget.onChangeLanguage, widget.onBuyProduct, filter, redirect);
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
                return _getFirstFilterRoute(MaterialPageRoute(
                    builder: (context) => PlantList(widget.onChangeLanguage, widget.onBuyProduct, {}, count, path)));
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
