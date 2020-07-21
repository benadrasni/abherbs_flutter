import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'observation_edit.dart';

class ObservationLogs extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  ObservationLogs(this.currentUser, this.myLocale, this.onChangeLanguage);

  @override
  _ObservationLogsState createState() => _ObservationLogsState();
}

class _ObservationLogsState extends State<ObservationLogs> {
  GlobalKey<ScaffoldState> _key;
  DateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _key = new GlobalKey<ScaffoldState>();
    _dateFormat = DateFormat.yMMMMEEEEd(widget.myLocale.toString()).add_jm();
  }

  Widget getItems(Map<dynamic, dynamic> observations) {
    var items = observations.keys.where((x) => x != firebaseAttributeTime).map((id) {
      return FutureBuilder<Observation>(
          future: privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsByDate).child(firebaseAttributeList).child(id.toString()).once().then((snapshot) {
            var observation = Observation.fromJson(snapshot.key, snapshot.value);
            observation.status = observations[firebaseAttributeStatus];
            return observation;
          }),
          builder: (BuildContext context, AsyncSnapshot<Observation> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return GestureDetector(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(snapshot.data.plant),
                      Text(_dateFormat.format(snapshot.data.date)),
                      snapshot.data.status == firebaseValueSuccess ? Icon(Icons.done) : Icon(Icons.error)
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ObservationEdit(widget.currentUser, Localizations.localeOf(context), widget.onChangeLanguage, snapshot.data),
                          settings: RouteSettings(name: 'ObservationLogs')),
                    );
                  },
                );
              default:
                return Container(
                  width: 0.0,
                  height: 0.0,
                );
            }
          });
    }).toList();

    return Container(
      padding: EdgeInsets.all(10.0),
      alignment: AlignmentDirectional.centerStart,
      child: Column(children: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle listTextStyle = TextStyle(
      fontSize: 18.0,
    );

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).observation_logs),
      ),
      body: MyFirebaseAnimatedList(
          shrinkWrap: true,
          defaultChild: Center(child: CircularProgressIndicator()),
          query: logsObservationsReference.child(widget.currentUser.uid).orderByChild(firebaseAttributeTime),
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
            return Card(child: Column(children: [
              ListTile(
                title: Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.key)))),
                leading: Icon(Icons.cloud_upload),
                onTap: () {},
              ),
              getItems(snapshot.value),
            ]),);
          }),
    );
  }
}
