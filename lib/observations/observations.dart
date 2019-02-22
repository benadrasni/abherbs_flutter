import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class Observations extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  Observations(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct);

  @override
  _ObservationsState createState() => _ObservationsState();
}

const Key _publicKey = Key('public');
const Key _privateKey = Key('private');

class _ObservationsState extends State<Observations> {
  Key _key;
  DateFormat _dateFormat;
  DateFormat _timeFormat;
  bool _isPublic;
  Query _privateQuery;
  Query _publicQuery;
  Query _query;
  Map<String, String> _translationCache;

  void _setIsPublic(bool isPublic) {
    setState(() {
      _isPublic = isPublic;
      _key = _isPublic ? _publicKey : _privateKey;
      _query = _isPublic ? _publicQuery : _privateQuery;
    });
  }

  @override
  void initState() {
    super.initState();
    _key = _privateKey;
    initializeDateFormatting();
    _dateFormat = new DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = new DateFormat.Hms(widget.myLocale.toString());
    _isPublic = false;
    _privateQuery = privateObservationsReference
        .child(widget.currentUser.uid)
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .orderByChild(firebaseAttributeOrder);
    _publicQuery = publicObservationsReference.child(firebaseObservationsByDate).child(firebaseAttributeList).orderByChild(firebaseAttributeOrder);
    _query = _privateQuery;
    _translationCache = {};

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    double mapWidth = MediaQuery.of(context).size.width;
    double mapHeigth = 100.0;

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).observations),
            Row(
              children: [
                Icon(Icons.person),
                Switch(
                  value: _isPublic,
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  onChanged: (bool value) {
                    _setIsPublic(value);
                  },
                ),
                Icon(Icons.people),
              ],
            ),
          ],
        ),
      ),
      body: FirebaseAnimatedList(
          key: _key,
          defaultChild: Center(child: CircularProgressIndicator()),
          query: _query,
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
            Observation observation = Observation.fromJson(snapshot.key, snapshot.value);

            Locale myLocale = Localizations.localeOf(context);
            Future<String> nameF = _translationCache.containsKey(observation.plantName)
                ? Future<String>(() {
                    return _translationCache[observation.plantName];
                  })
                : translationsReference
                    .child(getLanguageCode(myLocale.languageCode))
                    .child(observation.plantName)
                    .child(firebaseAttributeLabel)
                    .once()
                    .then((DataSnapshot snapshot) {
                    if (snapshot.value != null) {
                      _translationCache[observation.plantName] = snapshot.value;
                      return snapshot.value;
                    } else {
                      return null;
                    }
                  });

            return Card(
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                FutureBuilder<String>(
                    future: nameF,
                    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                      String labelLocal = observation.plantName;
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.data != null) {
                          labelLocal = snapshot.data;
                        }
                      }
                      return ListTile(
                        title: Text(labelLocal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),),
                        subtitle: Text(labelLocal != observation.plantName ? observation.plantName : ''),
                        trailing: Column(children:[
                          Text(_dateFormat.format(observation.dateTime)),
                          Text(_timeFormat.format(observation.dateTime)),
                        ],),
                        onTap: () {
                          //_onPressed(myLocale, name);
                        },
                      );
                    }),
                Container(
                  padding: EdgeInsets.only(bottom: 5.0),
                  height: mapHeigth,
                  child: CachedNetworkImage(
                    fit: BoxFit.contain,
                    width: mapWidth,
                    height: mapHeigth,
                    placeholder: Container(
                      width: 0.0,
                      height: 0.0,
                    ),
                    imageUrl: getMapImageUrl(observation.latitude, observation.longitude, mapWidth, mapHeigth),
                  ),
                ),
              ]),
            );
          }),
    );
  }
}
