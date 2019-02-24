import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:flutter/material.dart';

Future<void> rateDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(S.of(context).rate_question),
        content: Text(S.of(context).rate_text),
        actions: <Widget>[
          FlatButton(
            child: Text(S.of(context).rate_never),
            onPressed: () {
              Prefs.setString(keyRateState, rateStateNever).then((value) {
                Navigator.of(context).pop();
              }).catchError((error) {
                Navigator.of(context).pop();
              });
            },
          ),
          FlatButton(
            child: Text(S.of(context).rate_later),
            onPressed: () {
              Prefs.setInt(keyRateCount, rateCountInitial);
              Prefs.setString(keyRateState, rateStateInitial).then((value) {
                Navigator.of(context).pop();
              }).catchError((error) {
                Navigator.of(context).pop();
              });
            },
          ),
          FlatButton(
            child: Text(S.of(context).rate),
            onPressed: () {
              Prefs.setString(keyRateState, rateStateDid).then((value) {
                Navigator.of(context).pop();
              }).catchError((error) {
                Navigator.of(context).pop();
              });
              if (Platform.isAndroid) {
                launchURL(playStore);
              } else {
                launchURL(appStore);
              }
            },
          ),
        ],
      );
    },
  );
}

Future<void> observationDialog(BuildContext mainContext, GlobalKey<ScaffoldState> key) async {
  return showDialog(
      context: mainContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).observations),
          content: Text(S.of(context).observation_no_login),
          actions: [
            FlatButton(
              child: Text(S.of(context).close.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  )),
              onPressed: () {
                Navigator.of(context).pop();
                key.currentState.openDrawer();
              },
            )
          ],
        );
      });
}
