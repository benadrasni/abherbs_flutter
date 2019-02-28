import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/observations/observation_edit.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class ObservationView extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Observation observation;

  ObservationView(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct, this.observation);

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
    _dateFormat = new DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = new DateFormat.Hms(widget.myLocale.toString());
  }

  @override
  Widget build(BuildContext context) {
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
        : translationsReference
            .child(getLanguageCode(myLocale.languageCode))
            .child(widget.observation.plant)
            .child(firebaseAttributeLabel)
            .once()
            .then((DataSnapshot snapshot) {
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
                children: [
                  Text(_dateFormat.format(widget.observation.date)),
                  Text(_timeFormat.format(widget.observation.date)),
                ],
              ),
              onTap: () {
                goToDetail(context, myLocale, widget.observation.plant, widget.onChangeLanguage, widget.onBuyProduct, {});
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
            MaterialPageRoute(builder: (context) => ObservationMap(myLocale, widget.observation, mapModeView)),
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
          return Stack(children: [
            getImage(widget.observation.photoPaths[position], placeholder, width: mapWidth, height: mapWidth, fit: BoxFit.cover),
            Container(
              padding: EdgeInsets.all(5.0),
              child: Text(
                (position + 1).toString() + ' / ' + widget.observation.photoPaths.length.toString(),
                style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
          ]);
        },
      ),
    ));

    if (widget.observation.note != null && widget.observation.note.isNotEmpty && widget.observation.id.startsWith(widget.currentUser.uid)) {
      widgets.add(Card(color: Theme.of(context).buttonColor, child:Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        height: 50.0,
        alignment: Alignment.topLeft,
        child: Text(widget.observation.note, style: TextStyle(fontSize: 16.0),
          textAlign: TextAlign.start,),
      )));
    }

    return Card(
      child: widget.observation.id.startsWith(widget.currentUser.uid)
          ? Stack(children: [
              Column(mainAxisSize: MainAxisSize.min, children: widgets),
              Positioned(
                bottom: 20.0,
                right: 20.0,
                child: FloatingActionButton(
                  heroTag: widget.observation.id,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ObservationEdit(widget.currentUser, myLocale, widget.onChangeLanguage, widget.onBuyProduct, widget.observation)),
                  );
                },
                child: Icon(Icons.edit),
              ),),
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: widgets),
    );
  }
}
