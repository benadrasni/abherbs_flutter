import 'dart:async';

import 'package:flutter/material.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:abherbs_flutter/generated/l10n.dart';

class ObservationMap extends StatefulWidget {
  final Locale myLocale;
  final Observation observation;
  final String mode;
  ObservationMap(this.myLocale, this.observation, this.mode);

  @override
  _ObservationMapState createState() => _ObservationMapState();
}

class _ObservationMapState extends State<ObservationMap> {
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;
  late MarkerId _markerId;
  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  late Future<String> nameF;

  void _updateMarker(CameraPosition _position) {
    if (widget.mode == mapModeEdit) {
      final Marker marker = _markers[_markerId]!;
      setState(() {
        _markers[_markerId] = marker.copyWith(
          positionParam: LatLng(
            _position.target.latitude,
            _position.target.longitude,
          ),
        );
      });
    }
  }

  void _onSaveButtonPressed(BuildContext context) {
    Marker marker = _markers[_markerId]!;
    Navigator.pop(
        context, LatLng(marker.position.latitude, marker.position.longitude));
  }

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = DateFormat.Hms(widget.myLocale.toString());
    _markerId = MarkerId(widget.observation.plant);
    _markers = <MarkerId, Marker>{};
    _markers[_markerId] = Marker(
      markerId: _markerId,
      //draggable: true,
      position: LatLng(
        widget.observation.latitude,
        widget.observation.longitude,
      ),
    );

    nameF = translationCache.containsKey(widget.observation.plant)
        ? Future<String>(() {
            return translationCache[widget.observation.plant]!;
          })
        : translationsReference
            .child(getLanguageCode(widget.myLocale.languageCode))
            .child(widget.observation.plant)
            .child(firebaseAttributeLabel)
            .once()
            .then((event) {
            if (event.snapshot.value != null) {
              translationCache[widget.observation.plant] = event.snapshot.value as String;
              return event.snapshot.value as String;
            } else {
              return widget.observation.plant;
            }
          });
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    widgets.add(GoogleMap(
      onCameraMove: ((_position) => _updateMarker(_position)),
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.observation.latitude,
            widget.observation.longitude),
        zoom: 13,
      ),
      markers: Set<Marker>.of(_markers.values),
    ));

    if (widget.mode == mapModeEdit) {
      widgets.add(Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            heroTag: 'save',
            onPressed: () {
              _onSaveButtonPressed(context);
            },
            materialTapTargetSize: MaterialTapTargetSize.padded,
            child: const Icon(Icons.save, size: 36.0),
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).observation),
      ),
      body: Column(
        children: [
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
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  subtitle: labelLocal != widget.observation.plant
                      ? Text(widget.observation.plant)
                      : null,
                  trailing: Column(
                    children: [
                      Text(_dateFormat.format(widget.observation.date)),
                      Text(_timeFormat.format(widget.observation.date)),
                    ],
                  ),
                );
              }),
          Expanded(
            child: Stack(
              children: widgets,
            ),
          ),
        ],
      ),
    );
  }
}
