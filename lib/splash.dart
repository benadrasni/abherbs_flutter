import 'dart:async';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';

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
    Navigator.pushReplacement(context, getNextFilterRoute(null, widget.onChangeLanguage, new Map<String, String>()));
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