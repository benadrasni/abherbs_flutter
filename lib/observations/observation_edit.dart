import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:exif/exif.dart';

class ObservationEdit extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Observation observation;

  ObservationEdit(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct, this.observation);

  @override
  _ObservationEditState createState() => _ObservationEditState();
}

class _ObservationEditState extends State<ObservationEdit> {
  DateFormat _dateFormat;
  DateFormat _timeFormat;

  Future<void> _getImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);

    // store file
    var dir = storageObservations + widget.currentUser.uid + '/' + widget.observation.plantName.replaceAll(' ', '_');
    var prefix = "unknown_";
    var names = widget.observation.plantName.toLowerCase().split(' ');
    if (names.length > 1) {
      prefix = names[0].substring(0, 1) + names[1].substring(0, 1) + '_';
    }
    var suffix = image.path.indexOf('.', image.path.lastIndexOf('/')) > -1 ? image.path.substring(image.path.lastIndexOf('.')) : defaultPhotoExtension;
    var filename = prefix + DateTime.now().millisecondsSinceEpoch.toString() + suffix;

    String rootPath = (await getApplicationDocumentsDirectory()).path;
    await Directory('$rootPath/$dir').create(recursive: true);
    image.copy('$rootPath/$dir/$filename');
    await File('$rootPath/$dir/$filename');
    widget.observation.photoUrls.add('$dir/$filename');

    // store exif data
    Map<String, IfdTag> data = await readExifFromBytes(await image.readAsBytes());

    if (data != null && data.isNotEmpty) {
      widget.observation.latitude = getLatitudeFromExif(data['GPS GPSLatitudeRef'], data['GPS GPSLatitude']);
      widget.observation.longitude = getLongitudeFromExif(data['GPS GPSLongitudeRef'], data['GPS GPSLongitude']);
      widget.observation.dateTime= getDateTimeFromExif(data['Image DateTime']) ?? DateTime.now();
//      for (String key in data.keys) {
//        print("$key (${data[key].tagType}): ${data[key]}");
//      }
    }
    setState(() {});
  }

  Future<void> _deleteImage(int position) async {
    String rootPath = (await getApplicationDocumentsDirectory()).path;
    var filename = widget.observation.photoUrls[position];
    File file = await File('$rootPath/$filename');
    file.delete();
    widget.observation.photoUrls.removeAt(position);

    setState(() {});
  }

  void _saveObservation() {

  }

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
          placeholder: Container(
            width: mapWidth,
            height: mapHeight,
          ),
          imageUrl: getMapImageUrl(widget.observation.latitude, widget.observation.longitude, mapWidth, mapHeight),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObservationMap(myLocale, widget.observation, mapModeEdit)),
          ).then((value) {
            widget.observation.latitude = value.latitude;
            widget.observation.longitude = value.longitude;
            setState(() {});
          });
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (position + 1).toString() + ' / ' + widget.observation.photoUrls.length.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.white,),
                    onPressed: () {
                      _deleteImage(position);
                    },
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
    ));

    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).observation),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add_a_photo),
              onPressed: () {
                _getImage(ImageSource.camera);
              },
            ),
            IconButton(
              icon: Icon(Icons.add_photo_alternate),
              onPressed: () {
                _getImage(ImageSource.gallery);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {},
            ),
          ],
        ),
        body: Card(
          child: Column(mainAxisSize: MainAxisSize.min, children: widgets),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _saveObservation();
            Navigator.pop(context);
          },
          child: Icon(Icons.save),
        ),
    );
  }
}
