import 'dart:async';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  Splash(this.onChangeLanguage);

  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<Splash> {

  startTime() async {
    var _duration = new Duration(seconds: 1);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() {
    Prefs.getBoolF(keyAlwaysMyRegion, false).then((value) {
      Map<String, String> filter = {};
      if (value) {
        Prefs.getStringF(keyMyRegion, null).then((value) {
          if (value != null) {
            filter[filterDistribution] = value;
          }
          Navigator.pushReplacement(context, getNextFilterRoute(null, widget.onChangeLanguage, filter));
        });
      } else {
        Navigator.pushReplacement(context, getNextFilterRoute(null, widget.onChangeLanguage, filter));
      }
    });
  }

  @override
  void initState() {
    super.initState();
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