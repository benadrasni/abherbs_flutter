import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/utils/fullscreen.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../main.dart';

class ObservationView extends StatefulWidget {
  final AppUser currentUser;
  final Locale myLocale;
  final Observation observation;

  ObservationView(this.currentUser, this.myLocale, this.observation);

  @override
  _ObservationViewState createState() => _ObservationViewState();
}

class _ObservationViewState extends State<ObservationView> {
  DateFormat _dateFormat;
  DateFormat _timeFormat;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _dateFormat = DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = DateFormat.Hms(widget.myLocale.toString());
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
    var self = this;
    var mainContext = context;
    double mapWidth = MediaQuery.of(context).size.width;
    double mapHeight = 100.0;

    var placeholder = Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(),
      Container(
        width: mapWidth,
        height: mapWidth,
      ),
    ]);

    Locale myLocale = Localizations.localeOf(context);
    Future<String> nameF = translationCache.containsKey(widget.observation.plant)
        ? Future<String>(() {
            return translationCache[widget.observation.plant];
          })
        : translationsReference.child(getLanguageCode(myLocale.languageCode)).child(widget.observation.plant).child(firebaseAttributeLabel).once().then((DataSnapshot snapshot) {
            if (snapshot.value != null) {
              translationCache[widget.observation.plant] = snapshot.value;
              return snapshot.value;
            } else {
              return null;
            }
          });

    var widgets = <Widget>[];
    widgets.add(
      FutureBuilder<String>(
          future: nameF,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            String labelLocal = widget.observation.plant;
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data != null) {
                labelLocal = snapshot.data;
              }
            }
            return ListTile(
              title: Text(
                labelLocal,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              subtitle: labelLocal != widget.observation.plant ? Text(widget.observation.plant) : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_dateFormat.format(widget.observation.date)),
                  Text(_timeFormat.format(widget.observation.date)),
                ],
              ),
              onTap: () {
                goToDetail(self, mainContext, myLocale, widget.observation.plant, {});
              },
            );
          }),
    );

    widgets.add(
      FlatButton(
        padding: EdgeInsets.all(5.0),
        child: CachedNetworkImage(
          fit: BoxFit.contain,
          width: mapWidth,
          height: mapHeight,
          placeholder: (context, url) => Container(
            width: mapWidth,
            height: mapHeight,
          ),
          imageUrl: getMapImageUrl(widget.observation.latitude, widget.observation.longitude, mapWidth, mapHeight),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObservationMap(myLocale, widget.observation, mapModeView), settings: RouteSettings(name: 'ObservationMap')),
          );
        },
      ),
    );

    widgets.add(Container(
      padding: EdgeInsets.all(5.0),
      width: mapWidth,
      height: mapWidth,
      child: PageView.builder(
        itemCount: widget.observation.photoPaths.length,
        itemBuilder: (context, position) {
          if (widget.observation.status == firebaseValueReview) {
            return Center(
                child: Image(
              image: AssetImage('res/images/review.png'),
            ));
          } else {
            return GestureDetector(
              child: Stack(children: [
                getImage(widget.observation.photoPaths[position], placeholder, width: mapWidth, height: mapWidth, fit: BoxFit.cover),
                Container(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    (position + 1).toString() + ' / ' + widget.observation.photoPaths.length.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
              onTap: () {
                var newUrl = widget.observation.photoPaths[position].toString().replaceAll(defaultExtension, defaultPhotoExtension);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FullScreenPage(newUrl), settings: RouteSettings(name: 'FullScreen')),
                );
              },
            );
          }
        },
      ),
    ));

    if (widget.currentUser != null && widget.observation.note != null && widget.observation.note.isNotEmpty && widget.observation.id.startsWith(widget.currentUser.firebaseUser.uid)) {
      widgets.add(Card(
          color: Theme.of(context).buttonColor,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            alignment: Alignment.topLeft,
            child: Text(
              widget.observation.note,
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.start,
            ),
          )));
    }

    return Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: widgets),
    );
  }
}
