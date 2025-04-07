import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/fullscreen.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../main.dart';

class ObservationView extends StatefulWidget {
  final Locale myLocale;
  final Observation observation;

  ObservationView(this.myLocale, this.observation);

  @override
  _ObservationViewState createState() => _ObservationViewState();
}

class _ObservationViewState extends State<ObservationView> {
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;

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
            return translationCache[widget.observation.plant]!;
          })
        : translationsReference.child(getLanguageCode(myLocale.languageCode)).child(widget.observation.plant).child(firebaseAttributeLabel).once().then((event) {
            if (event.snapshot.value != null) {
              translationCache[widget.observation.plant] = event.snapshot.value as String;
              return event.snapshot.value as String;
            } else {
              return widget.observation.plant;
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
                labelLocal = snapshot.data!;
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
      TextButton(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
              EdgeInsets.all(5.0)),
        ),
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

    if (Auth.appUser != null && widget.observation.note.isNotEmpty && widget.observation.id.startsWith(Auth.appUser!.uid)) {
      widgets.add(Card(
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
