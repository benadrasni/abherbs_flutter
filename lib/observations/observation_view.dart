import 'dart:async';

import 'package:abherbs_flutter/entity/observation.dart';
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
  int _position;
  DateFormat _dateFormat;
  DateFormat _timeFormat;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _dateFormat = new DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = new DateFormat.Hms(widget.myLocale.toString());
    _position = 0;
  }

  @override
  Widget build(BuildContext context) {
    double mapWidth = MediaQuery.of(context).size.width;
    double mapHeight = 100.0;

    var placeholder = Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(),
      Image(
        image: AssetImage('res/images/placeholder.webp'),
      ),
    ]);

    Locale myLocale = Localizations.localeOf(context);
    Future<String> nameF = translationCache.containsKey(widget.observation.plantName)
        ? Future<String>(() {
            return translationCache[widget.observation.plantName];
          })
        : translationsReference
            .child(getLanguageCode(myLocale.languageCode))
            .child(widget.observation.plantName)
            .child(firebaseAttributeLabel)
            .once()
            .then((DataSnapshot snapshot) {
            if (snapshot.value != null) {
              translationCache[widget.observation.plantName] = snapshot.value;
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
            String labelLocal = widget.observation.plantName;
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
              subtitle: labelLocal != widget.observation.plantName ? Text(widget.observation.plantName) : null,
              trailing: Column(
                children: [
                  Text(_dateFormat.format(widget.observation.dateTime)),
                  Text(_timeFormat.format(widget.observation.dateTime)),
                ],
              ),
              onTap: () {
                goToDetail(context, myLocale, widget.observation.plantName, widget.onChangeLanguage, widget.onBuyProduct, {});
              },
            );
          }),
    );

    widgets.add(
      FlatButton(
        padding: EdgeInsets.only(bottom: 5.0),
        child: CachedNetworkImage(
          fit: BoxFit.contain,
          width: mapWidth,
          height: mapHeight,
          placeholder: Container(
            width: 0.0,
            height: 0.0,
          ),
          imageUrl: getMapImageUrl(widget.observation.latitude, widget.observation.longitude, mapWidth, mapHeight),
        ),
        onPressed: () {},
      ),
    );

    widgets.add(
      ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              child: Padding(
                child: Icon(Icons.arrow_back_ios),
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
              ),
              onTap: () {},
            ),
            Text((_position + 1).toString() + ' / ' + widget.observation.photoUrls.length.toString()),
            GestureDetector(
              child: Padding(
                child: Icon(Icons.arrow_forward_ios),
                padding: EdgeInsets.only(left: 10.0, right: 10.0),
              ),
              onTap: () {},
            ),
          ],
        ),
        trailing: widget.observation.key.startsWith(widget.currentUser.uid) ? Icon(Icons.edit) : null,
      ),
    );

    widgets.add(Container(
      padding: EdgeInsets.all(5.0),
      child: getImage(widget.observation.photoUrls[_position], placeholder),
    ));

    return Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: widgets),
    );
  }
}
