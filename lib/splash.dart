import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final void Function() onBuyProduct;
  Splash(this.onChangeLanguage, this.onBuyProduct);

  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<Splash> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _onLaunchWasFired = false;

  startTime() async {
    var _duration = new Duration(milliseconds: 500);
    return new Timer(_duration, navigationPage);
  }

  void firebaseCloudMessagingListeners() {
    if (Platform.isIOS) iOSPermission();

    _firebaseMessaging.getToken().then((token){
      print('token $token');
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        _onLaunchWasFired = true;
        print('on launch $message');
        String action = message['action'];
        if (action != null) {
          switch (action) {
            case 'browse':
              String uri = message['uri'];
              if (uri != null) {
                launchURL(uri);
              }
              break;
            case 'list':
              String count = message['count'];
              String path = message['path'];
              if (count != null && path != null) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PlantList(widget.onChangeLanguage, widget.onBuyProduct, {}, count, path)));
              }
              break;
          }
        }
      },
    );
  }

  void iOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true)
    );
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings)
    {
      print("Settings registered: $settings");
    });
  }

  void navigationPage() {
    if (!_onLaunchWasFired) {
      Prefs.getBoolF(keyAlwaysMyRegion, false).then((value) {
        Map<String, String> filter = {};
        if (value) {
          Prefs.getStringF(keyMyRegion, null).then((value) {
            if (value != null) {
              filter[filterDistribution] = value;
            }
            Navigator.pushReplacement(context, getNextFilterRoute(null, widget.onChangeLanguage, widget.onBuyProduct, filter));
          });
        } else {
          Navigator.pushReplacement(context, getNextFilterRoute(null, widget.onChangeLanguage, widget.onBuyProduct, filter));
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    firebaseCloudMessagingListeners();
    startTime();
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