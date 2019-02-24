import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/observations/observation_edit.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class ObservationPlantView extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Observation observation;

  ObservationPlantView(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct, this.observation);

  @override
  _ObservationPlantViewState createState() => _ObservationPlantViewState();
}

class _ObservationPlantViewState extends State<ObservationPlantView> {
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
    var widgets = <Widget>[];
    widgets.add(ListTile(
      leading: widget.observation.id.startsWith(widget.currentUser.uid)
          ? CircleAvatar(
              backgroundColor: Theme.of(context).accentColor,
              child: Icon(
                Icons.edit,
                color: Colors.white,
              ))
          : null,
      title: Text(_dateFormat.format(widget.observation.dateTime) + ' ' + _timeFormat.format(widget.observation.dateTime)),
      onTap: () {
        if (widget.observation.id.startsWith(widget.currentUser.uid)) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ObservationEdit(widget.currentUser, myLocale, widget.onChangeLanguage, widget.onBuyProduct, widget.observation)),
          );
        }
      },
    ));

    widgets.add(
      FlatButton(
        padding: EdgeInsets.all(5.0),
        child: CachedNetworkImage(
          fit: BoxFit.contain,
          width: mapWidth,
          height: mapHeight,
          placeholder: Container(
            width: mapWidth,
            height: mapHeight,
          ),
          imageUrl: getMapImageUrl(widget.observation.latitude, widget.observation.longitude, mapWidth, mapHeight),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObservationMap(myLocale, widget.observation)),
          );
        },
      ),
    );

    widgets.add(Container(
      padding: EdgeInsets.all(5.0),
      width: mapWidth,
      height: mapWidth,
      child: PageView.builder(
        itemCount: widget.observation.photoUrls.length,
        itemBuilder: (context, position) {
          return Stack(children: [
            getImage(widget.observation.photoUrls[position], placeholder, width: mapWidth, height: mapWidth, fit: BoxFit.cover),
            Container(
              padding: EdgeInsets.all(5.0),
              child: Text(
                (position + 1).toString() + ' / ' + widget.observation.photoUrls.length.toString(),
                style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
          ]);
        },
      ),
    ));

    return Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: widgets),);
  }
}
