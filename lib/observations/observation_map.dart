import 'package:flutter/material.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:abherbs_flutter/generated/i18n.dart';

class ObservationMap extends StatelessWidget {
  final Locale myLocale;
  final Observation observation;
  GoogleMapController _mapController;
  ObservationMap(this.myLocale, this.observation);

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.addMarker(MarkerOptions(
      position: LatLng(
        observation.latitude,
        observation.longitude,
      ),
      icon: BitmapDescriptor.defaultMarker,
    ),);
  }

  @override
  Widget build(BuildContext context) {

    DateFormat _dateFormat = new DateFormat.yMMMMd(myLocale.toString());
    DateFormat  _timeFormat = new DateFormat.Hms(myLocale.toString());

    Future<String> nameF = translationCache.containsKey(observation.plantName)
        ? Future<String>(() {
      return translationCache[observation.plantName];
    })
        : translationsReference
        .child(getLanguageCode(myLocale.languageCode))
        .child(observation.plantName)
        .child(firebaseAttributeLabel)
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        translationCache[observation.plantName] = snapshot.value;
        return snapshot.value;
      } else {
        return null;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).observation),
      ),
      body: Column(
        children: [
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
                  title: Text(
                    labelLocal,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  subtitle: labelLocal != observation.plantName ? Text(observation.plantName) : null,
                  trailing: Column(
                    children: [
                      Text(_dateFormat.format(observation.dateTime)),
                      Text(_timeFormat.format(observation.dateTime)),
                    ],
                  ),
                );
              }),
          Expanded(child:GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(observation.latitude, observation.longitude),
              zoom: 13,
            ),
          ),),
        ],
      ),
    );
  }
}
