import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/dialogs.dart';
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
  TextEditingController _noteController = TextEditingController();

  Future<void> _getImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);

    // store file
    var dir = storageObservations + widget.currentUser.uid + '/' + widget.observation.plant.replaceAll(' ', '_');
    var prefix = "unknown_";
    var names = widget.observation.plant.toLowerCase().split(' ');
    if (names.length > 1) {
      prefix = names[0].substring(0, 1) + names[1].substring(0, 1) + '_';
    }
    var suffix =
        image.path.indexOf('.', image.path.lastIndexOf('/')) > -1 ? image.path.substring(image.path.lastIndexOf('.')) : defaultPhotoExtension;
    var filename = prefix + DateTime.now().millisecondsSinceEpoch.toString() + suffix;

    String rootPath = (await getApplicationDocumentsDirectory()).path;
    await Directory('$rootPath/$dir').create(recursive: true);
    image.copy('$rootPath/$dir/$filename');
    await File('$rootPath/$dir/$filename');
    widget.observation.photoPaths.add('$dir/$filename');

    // store exif data
    Map<String, IfdTag> data = await readExifFromBytes(await image.readAsBytes());

    if (data != null && data.isNotEmpty) {
      widget.observation.latitude = getLatitudeFromExif(data['GPS GPSLatitudeRef'], data['GPS GPSLatitude']);
      widget.observation.longitude = getLongitudeFromExif(data['GPS GPSLongitudeRef'], data['GPS GPSLongitude']);
      widget.observation.date = getDateTimeFromExif(data['Image DateTime']) ?? DateTime.now();
//      for (String key in data.keys) {
//        print("$key (${data[key].tagType}): ${data[key]}");
//      }
    }
    setState(() {});
  }

  Future<void> _deleteImage(int position) async {
    String rootPath = (await getApplicationDocumentsDirectory()).path;
    var filename = widget.observation.photoPaths[position];
    File file = File('$rootPath/$filename');
    file.delete();
    widget.observation.photoPaths.removeAt(position);

    setState(() {});
  }

  Future<bool> _saveObservation(BuildContext context) async {
    if (widget.observation.photoPaths.length > 0 && widget.observation.latitude != null && widget.observation.longitude != null) {
      if (widget.observation.id == null) {
        widget.observation.id = widget.currentUser.uid + '_' + widget.observation.date.millisecondsSinceEpoch.toString();
      }
      widget.observation.order = -1 * widget.observation.date.millisecondsSinceEpoch;
      widget.observation.note = _noteController.text;

      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(widget.observation.id)
          .set(widget.observation.toJson());
      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByPlant)
          .child(widget.observation.plant)
          .child(firebaseAttributeList)
          .child(widget.observation.id)
          .set(widget.observation.toJson());
      return true;
    } else {
      await infoDialog(context, S.of(context).observation, S.of(context).observation_not_saved);
      return false;
    }
  }

  Future<void> _deleteObservation() async {
    String rootPath = (await getApplicationDocumentsDirectory()).path;
    for (int position = 0; position < widget.observation.photoPaths.length; position++) {
      var path = widget.observation.photoPaths[position];
      File file = File('$rootPath/$path');
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (widget.observation.id != null) {
      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(widget.observation.id)
          .remove();
      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByPlant)
          .child(widget.observation.plant)
          .child(firebaseAttributeList)
          .child(widget.observation.id)
          .remove();
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _dateFormat = new DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = new DateFormat.Hms(widget.myLocale.toString());
    _noteController.text =  widget.observation.note;
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
      child: widget.observation.photoPaths.length == 0
          ? Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  child: Icon(Icons.add_a_photo, color: Theme.of(context).buttonColor, size: 80.0),
                  onTap: () {
                    _getImage(ImageSource.camera);
                  },
                ),
                SizedBox(width: 80.0),
                GestureDetector(
                  child: Icon(Icons.add_photo_alternate, color: Theme.of(context).buttonColor, size: 80.0),
                  onTap: () {
                    _getImage(ImageSource.gallery);
                  },
                )
              ]),
            )
          : PageView.builder(
              itemCount: widget.observation.photoPaths.length,
              itemBuilder: (context, position) {
                return Stack(children: [
                  getImage(widget.observation.photoPaths[position], placeholder, width: mapWidth, height: mapWidth, fit: BoxFit.cover),
                  Container(
                    padding: EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (position + 1).toString() + ' / ' + widget.observation.photoPaths.length.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: () {
                            deleteDialog(context, S.of(context).observation_photo_delete, S.of(context).observation_photo_delete_question)
                                .then((value) {
                              if (value) {
                                _deleteImage(position);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ]);
              },
            ),
    ));

    widgets.add(Container(
        padding: EdgeInsets.all(5.0),
        child: TextField(
          controller: _noteController,
          keyboardType: TextInputType.multiline,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: S.of(context).observation_note,
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                const Radius.circular(1.0),
              ),
              borderSide: BorderSide(
                color: Colors.black,
                width: 1.0,
              ),
            ),
          ),
        )));

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
            onPressed: () {
              deleteDialog(context, S.of(context).observation_delete, S.of(context).observation_delete_question).then((value) {
                if (value) {
                  _deleteObservation().then((_) => Navigator.of(context).pop());
                }
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            child: Column(mainAxisSize: MainAxisSize.min, children: widgets),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveObservation(context).then((result) {
            if (result) {
              Navigator.of(context).pop();
            }
          });
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
