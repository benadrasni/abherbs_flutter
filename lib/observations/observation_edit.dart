import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/observation_map.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:exif/exif.dart';
import 'package:permission_handler/permission_handler.dart';

class ObservationEdit extends StatefulWidget {
  final Locale myLocale;
  final Observation observation;

  ObservationEdit(this.myLocale, this.observation);

  @override
  _ObservationEditState createState() => _ObservationEditState();
}

class _ObservationEditState extends State<ObservationEdit> {
  final ImagePicker _picker = ImagePicker();

  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late Future<bool> _scaleDownPhotosF;
  late Observation _observation;
  late DateFormat _dateFormat;
  TextEditingController _noteController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  PageController _pageController = PageController();

  Future<void> _deleteImage(int position) async {
    String rootPath = (await getApplicationDocumentsDirectory()).path;
    var filename = _observation.photoPaths[position];
    File file = File('$rootPath/$filename');
    if (await file.exists()) {
      file.delete();
    }
    _observation.photoPaths.removeAt(position);

    setState(() {});
  }

  Future<bool> _saveObservation(BuildContext context) async {
    if (_observation.photoPaths.length == 0) {
      await infoDialog(context, S.of(context).observation, S.of(context).observation_missing_photo);
      return false;
    } else if (_observation.latitude == 0 && _observation.longitude == 0) {
      await infoDialog(context, S.of(context).observation, S.of(context).observation_missing_location);
      return false;
    } else {
      if (_observation.id.isEmpty) {
        _observation.id = Auth.appUser!.uid + '_' + DateTime.now().millisecondsSinceEpoch.toString();
      }
      _observation.order = -1 * _observation.date.millisecondsSinceEpoch;
      _observation.note = _noteController.text.isNotEmpty ? _noteController.text : "";

      await privateObservationsReference
          .child(Auth.appUser!.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(_observation.id)
          .set(_observation.toJson());
      await privateObservationsReference
          .child(Auth.appUser!.uid)
          .child(firebaseObservationsByPlant)
          .child(_observation.plant)
          .child(firebaseAttributeList)
          .child(_observation.id)
          .set(_observation.toJson());
      return true;
    }
  }

  Future<void> _getImage(GlobalKey<ScaffoldState> _key, ImageSource source) async {
    bool scaleDownPhotos = await _scaleDownPhotosF;
    var status = await Permission.accessMediaLocation.status;
    if (!status.isGranted) {
      await Permission.accessMediaLocation.request();
    }
    var image = await _picker.pickImage(source: source, maxWidth: scaleDownPhotos ? imageSizeScaleDown : null);
    if (image != null) {
      Map<String, IfdTag> exifData = await readExifFromBytes(await image.readAsBytes());
      IfdTag? dateTime = exifData['EXIF DateTimeOriginal'] ?? exifData['Image DateTime'];
      for (String path in _observation.photoPaths) {
        File? file = await Offline.getLocalFile(path);
        if (file != null) {
          Map<String, IfdTag> exifDataFile = await readExifFromBytes(await file.readAsBytes());
          IfdTag? dateTimeFile = exifDataFile['EXIF DateTimeOriginal'] ?? exifDataFile['Image DateTime'];
          if (dateTime != null && dateTimeFile != null && dateTime.toString() == dateTimeFile.toString()) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(S
                  .of(context)
                  .observation_photo_duplicate),
            ));
            return;
          }
        }
      }

      // store file
      var dir = storageObservations + Auth.appUser!.uid + '/' + _observation.plant.replaceAll(' ', '_');
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
      File(image.path).copy('$rootPath/$dir/$filename');
      _observation.photoPaths.add('$dir/$filename');

      // store exif data
      if (exifData.isNotEmpty) {
        var latitude = getLatitudeFromExif(exifData['GPS GPSLatitudeRef'], exifData['GPS GPSLatitude']);
        if (latitude != 0.0) {
          _observation.latitude = latitude;
        }
        var longitude = getLongitudeFromExif(exifData['GPS GPSLongitudeRef'], exifData['GPS GPSLongitude']);
        if (longitude != 0.0) {
          _observation.longitude = longitude;
        }
        _observation.date = getDateTimeFromExif(exifData['EXIF DateTimeOriginal'] ?? exifData['Image DateTime']);
        _dateController.text = _dateFormat.format(_observation.date);
      }
      if (_observation.photoPaths.length > 1) {
        _pageController.animateToPage(_observation.photoPaths.length - 1, duration: Duration(milliseconds: 400), curve: Curves.ease);
      }
      setState(() {});
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

    if (_observation.id.isNotEmpty) {
      await privateObservationsReference
          .child(Auth.appUser!.uid)
          .child(firebaseObservationsByDate)
          .child(firebaseAttributeList)
          .child(_observation.id)
          .remove();
      await privateObservationsReference
          .child(Auth.appUser!.uid)
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
    _scaleDownPhotosF = Prefs.getBoolF(keyScaleDownPhotos, false);
    _observation = Observation.from(widget.observation);
    initializeDateFormatting();
    _dateFormat = DateFormat.yMMMMEEEEd(widget.myLocale.toString()).add_jm();
    _noteController.text = _observation.note;
    _dateController.text = _dateFormat.format(_observation.date);
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
            return translationCache[_observation.plant]!;
          })
        : translationsReference
            .child(getLanguageCode(myLocale.languageCode))
            .child(_observation.plant)
            .child(firebaseAttributeLabel)
            .once()
            .then((event) {
            if (event.snapshot.value != null) {
              translationCache[_observation.plant] = event.snapshot.value as String;
              return event.snapshot.value as String;
            } else {
              return _observation.plant;
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
                labelLocal = snapshot.data!;
              }
            }
            return Column(
              children: [
                ListTile(
                  title: Text(
                    labelLocal,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  subtitle: labelLocal != _observation.plant ? Text(_observation.plant) : Text(""),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: DateTimeField(
                    format: _dateFormat,
                    controller: _dateController,
                    onShowPicker: (context, currentValue) async {
                      final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1900),
                          initialDate: currentValue ?? DateTime.now(),
                          lastDate: DateTime(2100));
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                          TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                        );

                        return DateTimeField.combine(date, time);
                      } else {
                        return currentValue;
                      }
                    },
                    onChanged: (dt) => setState(() => _observation.date = dt ?? DateTime.now()),
                  ),
                ),
                //Text(_timeFormat.format(_observation.date)),
              ],
            );
          }),
    );

    widgets.add(
      TextButton(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.all(5.0)),
        ),
        child: CachedNetworkImage(
          fit: BoxFit.contain,
          width: mapWidth,
          height: mapHeight,
          placeholder: (context, url) => Container(
                width: mapWidth,
                height: mapHeight,
              ),
          imageUrl: getMapImageUrl(_observation.latitude, _observation.longitude, mapWidth, mapHeight),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObservationMap(myLocale, _observation, mapModeEdit), settings: RouteSettings(name: 'ObservationMap')),
          ).then((value) {
            if (value != null) {
              _observation.latitude = value.latitude;
              _observation.longitude = value.longitude;
              setState(() {});
            }
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
                  child: Icon(Icons.add_a_photo, size: 80.0),
                  onTap: () {
                    _getImage(_key, ImageSource.camera);
                  },
                ),
                SizedBox(width: 80.0),
                GestureDetector(
                  child: Icon(Icons.add_photo_alternate, size: 80.0),
                  onTap: () {
                    _getImage(_key, ImageSource.gallery);
                  },
                )
              ]),
            )
          : PageView.builder(
              controller: _pageController,
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
                            color: Theme.of(context).primaryColor,
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
          maxLines: 5,
          maxLength: 300,
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
                if (result && mounted) {
                  Navigator.of(context).pop(true);
                }
              });
            },
            child: Icon(Icons.save),
          ),
        ),
      ),
    );
  }
}
