import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/observation_edit.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/fullscreen.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class ObservationPlantView extends StatefulWidget {
  final Locale myLocale;
  final Observation observation;
  final GlobalKey<ScaffoldState> parentKey;
  ObservationPlantView(this.myLocale, this.observation, this.parentKey);

  @override
  _ObservationPlantViewState createState() => _ObservationPlantViewState();
}

class _ObservationPlantViewState extends State<ObservationPlantView> {
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;

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
      leading: widget.observation.id.startsWith(Auth.appUser!.uid)
          ? CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                Icons.edit,
                color: Colors.white,
              ))
          : null,
      title: Text(_dateFormat.format(widget.observation.date) + ' ' + _timeFormat.format(widget.observation.date)),
      onTap: () {
        if (widget.observation.id.startsWith(Auth.appUser!.uid)) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObservationEdit(myLocale, widget.observation),
                settings: RouteSettings(name: 'ObservationEdit')),
          ).then((value) {
            if (value != null && value && widget.parentKey.currentState != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(S.of(context).observation_saved),
              ));
            }
          });
        }
      },
    ));

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

    if (widget.observation.note.isNotEmpty && widget.observation.id.startsWith(Auth.appUser!.uid)) {
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
