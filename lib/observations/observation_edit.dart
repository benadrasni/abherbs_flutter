import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/utils/utils.dart';
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
  GlobalKey<ScaffoldState> _key;
  Observation _observation;
  DateFormat _dateFormat;
  DateFormat _timeFormat;
  TextEditingController _noteController = TextEditingController();

  Future<void> _getImage(GlobalKey<ScaffoldState> _key, ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);
    Map<String, IfdTag> exifData = await readExifFromBytes(await image.readAsBytes());
    IfdTag dateTime = exifData['Image DateTime'];
    for (String path in _observation.photoPaths) {
      File file =  await Offline.getLocalFile(path);
      Map<String, IfdTag> exifDataFile = await readExifFromBytes(await file.readAsBytes());
      IfdTag dateTimeFile = exifDataFile['Image DateTime'];
      if (dateTime != null && dateTimeFile != null && dateTime.toString() == dateTimeFile.toString()) {
        _key.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).observation_photo_duplicate),
        ));
        return;
      }
    }

    // store file
    var dir = storageObservations + widget.currentUser.uid + '/' + _observation.plant.replaceAll(' ', '_');
    var prefix = "unknown_";
    var names = _observation.plant.toLowerCase().split(' ');
    if (names.length > 1) {
      prefix = names[0].substring(0, 1) + names[1].substring(0, 1) + '_';
    }
    var suffix =
        image.path.indexOf('.', image.path.lastIndexOf('/')) > -1 ? image.path.substring(image.path.lastIndexOf('.')) : defaultPhotoExtension;
    var filename = prefix + DateTime.now().millisecondsSinceEpoch.toString() + suffix;

    String rootPath = (await getApplicationDocumentsDirectory()).path;
    await Directory('$rootPath/$dir').create(recursive: true);
    image.copy('$rootPath/$dir/$filename');
    _observation.photoPaths.add('$dir/$filename');

    // store exif data
    if (exifData != null && exifData.isNotEmpty) {
      _observation.latitude = getLatitudeFromExif(exifData['GPS GPSLatitudeRef'], exifData['GPS GPSLatitude']);
      _observation.longitude = getLongitudeFromExif(exifData['GPS GPSLongitudeRef'], exifData['GPS GPSLongitude']);
      _observation.date = getDateTimeFromExif(exifData['Image DateTime']) ?? DateTime.now();
    }
    setState(() {});
  }

  Future<void> _deleteImage(int position) async {
    String rootPath = (await getApplicationDocumentsDirectory()).path;
    var filename = _observation.photoPaths[position];
    File file = File('$rootPath/$filename');
    file.delete();
    _observation.photoPaths.removeAt(position);

    setState(() {});
  }

  Future<bool> _saveObservation(BuildContext context) async {
    if (_observation.photoPaths.length > 0 && _observation.latitude != null && _observation.longitude != null) {
      if (_observation.id == null) {
        _observation.id = widget.currentUser.uid + '_' + _observation.date.millisecondsSinceEpoch.toString();
      }
      _observation.order = -1 * _observation.date.millisecondsSinceEpoch;
      _observation.note = _noteController.text;

      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(_observation.id)
          .set(_observation.toJson());
      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByPlant)
          .child(_observation.plant)
          .child(firebaseAttributeList)
          .child(_observation.id)
          .set(_observation.toJson());
      return true;
    } else {
      await infoDialog(context, S.of(context).observation, S.of(context).observation_not_saved);
      return false;
    }
  }

  Future<void> _deleteObservation() async {
    String rootPath = (await getApplicationDocumentsDirectory()).path;
    for (int position = 0; position < _observation.photoPaths.length; position++) {
      var path = _observation.photoPaths[position];
      File file = File('$rootPath/$path');
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (_observation.id != null) {
      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(_observation.id)
          .remove();
      await privateObservationsReference
          .child(widget.currentUser.uid)
          .child(firebaseObservationsByPlant)
          .child(_observation.plant)
          .child(firebaseAttributeList)
          .child(_observation.id)
          .remove();
    }
  }

  @override
  void initState() {
    super.initState();
    _key = new GlobalKey<ScaffoldState>();
    _observation = Observation.from(widget.observation);
    initializeDateFormatting();
    _dateFormat = new DateFormat.yMMMMd(widget.myLocale.toString());
    _timeFormat = new DateFormat.Hms(widget.myLocale.toString());
    _noteController.text =  _observation.note;
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
    Future<String> nameF = translationCache.containsKey(_observation.plant)
        ? Future<String>(() {
            return translationCache[_observation.plant];
          })
        : translationsReference
            .child(getLanguageCode(myLocale.languageCode))
            .child(_observation.plant)
            .child(firebaseAttributeLabel)
            .once()
            .then((DataSnapshot snapshot) {
            if (snapshot.value != null) {
              translationCache[_observation.plant] = snapshot.value;
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
            String labelLocal = _observation.plant;
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
              subtitle: labelLocal != _observation.plant ? Text(_observation.plant) : null,
              trailing: Column(
                children: [
                  Text(_dateFormat.format(_observation.date)),
                  Text(_timeFormat.format(_observation.date)),
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
          placeholder: (context, url) =>  Container(
            width: mapWidth,
            height: mapHeight,
          ),
          imageUrl: getMapImageUrl(_observation.latitude, _observation.longitude, mapWidth, mapHeight),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObservationMap(myLocale, _observation, mapModeEdit)),
          ).then((value) {
            _observation.latitude = value.latitude;
            _observation.longitude = value.longitude;
            setState(() {});
          });
        },
      ),
    );

    widgets.add(Container(
      padding: EdgeInsets.all(5.0),
      width: mapWidth,
      height: mapWidth,
      child: _observation.photoPaths.length == 0
          ? Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  child: Icon(Icons.add_a_photo, color: Theme.of(context).buttonColor, size: 80.0),
                  onTap: () {
                    _getImage(_key, ImageSource.camera);
                  },
                ),
                SizedBox(width: 80.0),
                GestureDetector(
                  child: Icon(Icons.add_photo_alternate, color: Theme.of(context).buttonColor, size: 80.0),
                  onTap: () {
                    _getImage(_key, ImageSource.gallery);
                  },
                )
              ]),
            )
          : PageView.builder(
              itemCount: _observation.photoPaths.length,
              itemBuilder: (context, position) {
                return Stack(children: [
                  getImage(_observation.photoPaths[position], placeholder, width: mapWidth, height: mapWidth, fit: BoxFit.cover),
                  Container(
                    padding: EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (position + 1).toString() + ' / ' + _observation.photoPaths.length.toString(),
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
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).observation),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: () {
              _getImage(_key, ImageSource.camera);
            },
          ),
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: () {
              _getImage(_key, ImageSource.gallery);
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
      floatingActionButton: Container(
    height: 70.0,
    width: 70.0,
    child: FittedBox(
    fit: BoxFit.fill,
    child: FloatingActionButton(
        onPressed: () {
          _saveObservation(context).then((result) {
            if (result) {
              Navigator.of(context).pop(true);
            }
          });
        },
        child: Icon(Icons.save),
      ),),),
    );
  }
}
