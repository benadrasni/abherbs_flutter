import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ObservationsMap extends StatefulWidget {
  final MarkerId newestMarker;
  final Map<MarkerId, Marker> markers;

  ObservationsMap(this.newestMarker, this.markers);

  @override
  _ObservationsMapState createState() => _ObservationsMapState();
}

class _ObservationsMapState extends State<ObservationsMap> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.markers[widget.newestMarker]!.position.latitude, widget.markers[widget.newestMarker]!.position.longitude),
          zoom: 3,
        ),
        markers: Set<Marker>.of(widget.markers.values),
      ),
      floatingActionButton: Container(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          fit: BoxFit.fill,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Icon(Icons.close),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
