import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SearchResult {
  double confidence;
  int count;
  String entityId;
  String labelInLanguage;
  String labelLatin;
  String path;
  Map<String, dynamic> plantDetails;
  List<dynamic> similarImages;
}

class SearchPhoto extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  SearchPhoto(this.currentUser, this.myLocale, this.onChangeLanguage);

  @override
  _SearchPhotoState createState() => _SearchPhotoState();
}

class _SearchPhotoState extends State<SearchPhoto> {
  FirebaseAnalytics _firebaseAnalytics;
  GlobalKey<ScaffoldState> _key;
  File _image;
  Future<List<SearchResult>> _searchResultF;
  Future<List<dynamic>> _genericEntitiesF;
  Future<String> _engineF;
  ImageLabeler imageLabeler;

  Future<void> _logPhotoSearchEvent() async {
    await _firebaseAnalytics.logEvent(name: 'search_photo');
  }

  Future<void> _getImage(GlobalKey<ScaffoldState> _key, ImageSource source, double maxSize) async {
    setState(() {
      _image = null;
      _searchResultF = Future<List<SearchResult>>(() {
        return null;
      });
    });
    var image = await ImagePicker.pickImage(source: source, maxWidth: maxSize);
    if (image != null) {
      _logPhotoSearchEvent();
      var engine = await _engineF;
      setState(() {
        _image = image;
        if (engine == plantIdEngine) {
          _searchResultF = _getSearchResultPlantId(image);
        } else {
          _searchResultF = _getSearchResult(image);
        }
      });
    }
  }

  Future<List<SearchResult>> _getSearchResultPlantId(File image) {
    List<int> imageBytes = image.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);

    Map<String, String> headers = {"Content-type": "application/json", "Api-Key": plantIdKey};
    var msg = jsonEncode({
      "images": [base64Image],
      "modifiers": plantIdModifiers,
      "plant_language": widget.myLocale.languageCode,
      "plant_details": plantIdPlantDetails
    });

    return http.post(plantIdEndpoint, headers: headers, body: msg).then((response) async {
      var results = <SearchResult>[];
      if (response.statusCode == 200) {
        Map responseBody = json.decode(response.body);
        for (var suggestion in responseBody['suggestions'] ) {
          String plantName = suggestion['plant_details']['scientific_name'];
          results.add(await rootReference.child(firebaseSearchPhoto + '/' + plantName.toLowerCase().replaceAll('.', '')).once().then((snapshot) {
            var result = SearchResult();
            result.labelLatin = plantName;
            result.entityId = suggestion['id'].toString();
            result.confidence = suggestion['probability'];
            result.plantDetails = suggestion['plant_details'];
            result.similarImages = suggestion['similar_images'];
            if (snapshot != null && snapshot.value != null) {
              result.count = snapshot.value['count'];
              result.path = snapshot.value['path'];
              result.labelInLanguage = '';
              if (result.path.contains('/')) {
                String path = result.path.substring(0, result.path.length - 5);
                result.labelLatin = path.substring(path.lastIndexOf('/') + 1);
              } else {
                result.labelLatin = result.path;
                translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(result.labelLatin).keepSynced(true);
                return translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(result.labelLatin).child(firebaseAttributeLabel)
                    .once()
                    .then((snapshot) {
                  if (snapshot.value != null) {
                    result.labelInLanguage = snapshot.value;
                  }
                  return result;
                });
              }
              if (translationCache.containsKey(result.labelLatin)) {
                result.labelInLanguage = translationCache[result.labelLatin];
                return result;
              } else {
                translationsTaxonomyReference.child(widget.myLocale.languageCode).child(result.labelLatin).keepSynced(true);
                return translationsTaxonomyReference.child(widget.myLocale.languageCode).child(result.labelLatin)
                    .once()
                    .then((snapshot) {
                  if (snapshot.value != null && snapshot.value.length > 0) {
                    translationCache[result.labelLatin] = snapshot.value[0];
                    result.labelInLanguage = snapshot.value[0];
                  }
                  return result;
                });
              }
            }

            return result;
          }));
        }
      }

      // save labels
      if (results.length > 0) {
        var userId = firebaseAttributeAnonymous;
        if (widget.currentUser != null) {
          userId = widget.currentUser.uid;
        }
        rootReference.child(firebaseUsersPhotoSearch)
            .child(userId)
            .child(DateTime.now().millisecondsSinceEpoch.toString())
            .set(results.map((searchResult) {
          Map<String, dynamic> labelMap = {};
          labelMap['entityId'] = searchResult.entityId;
          labelMap['language'] = widget.myLocale.languageCode;
          labelMap['confidence'] = searchResult.confidence;
          labelMap['plantDetails'] = searchResult.plantDetails;
          labelMap['similarImages'] = searchResult.similarImages;
          if (searchResult.labelLatin != null) {
            labelMap['label_latin'] = searchResult.labelLatin;
          }
          if (searchResult.labelInLanguage != null) {
            labelMap['label_language'] = searchResult.labelInLanguage;
          }
          return labelMap;
        }).toList());
      }

      return results;
    }).catchError((error, stackTrace) {
      FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: false);
    });
  }

  Future<List<SearchResult>> _getSearchResult(File image) {
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(image);

    return Future.wait([imageLabeler.processImage(visionImage), _genericEntitiesF]).then((value) async {
      List<ImageLabel> labels = value[0];
      List<dynamic> genericEntities = value[1];
      List<ImageLabel> significantLabels = [];
      for (ImageLabel label in labels) {
        if (!genericEntities.contains(label.entityId)) {
          significantLabels.add(label);
        }
      }

      var results = <SearchResult>[];
      for (ImageLabel label in significantLabels) {
        results.add(await rootReference.child(firebaseSearchPhoto + label.entityId).once().then((snapshot) {
          var result = SearchResult();
          result.labelLatin = _adjustLabel(label.text);
          result.entityId = label.entityId;
          result.confidence = label.confidence;
          if (snapshot != null && snapshot.value != null) {
            result.count = snapshot.value['count'];
            result.path = snapshot.value['path'];
            result.labelInLanguage = '';
            if (result.path.contains('/')) {
              String path = result.path.substring(0, result.path.length - 5);
              result.labelLatin = path.substring(path.lastIndexOf('/') + 1);
            } else {
              result.labelLatin = result.path;
              translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(result.labelLatin).keepSynced(true);
              return translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(result.labelLatin).child(firebaseAttributeLabel)
                  .once()
                  .then((snapshot) {
                if (snapshot.value != null) {
                  result.labelInLanguage = snapshot.value;
                }
                return result;
              });
            }
            if (translationCache.containsKey(result.labelLatin)) {
              result.labelInLanguage = translationCache[result.labelLatin];
              return result;
            } else {
              translationsTaxonomyReference.child(widget.myLocale.languageCode).child(result.labelLatin).keepSynced(true);
              return translationsTaxonomyReference.child(widget.myLocale.languageCode).child(result.labelLatin)
                  .once()
                  .then((snapshot) {
                if (snapshot.value != null && snapshot.value.length > 0) {
                  translationCache[result.labelLatin] = snapshot.value[0];
                  result.labelInLanguage = snapshot.value[0];
                }
                return result;
              });
            }
          }
          return result;
        }));
      }
      // save labels
      if (results.length > 0) {
        var userId = firebaseAttributeAnonymous;
        if (widget.currentUser != null) {
          userId = widget.currentUser.uid;
        }
        rootReference.child(firebaseUsersPhotoSearch)
            .child(userId)
            .child(DateTime.now().millisecondsSinceEpoch.toString())
            .set(results.map((searchResult) {
          Map<String, dynamic> labelMap = {};
          labelMap['entityId'] = searchResult.entityId;
          labelMap['language'] = widget.myLocale.languageCode;
          labelMap['confidence'] = searchResult.confidence;
          if (searchResult.labelLatin != null) {
            labelMap['label_latin'] = searchResult.labelLatin;
          }
          if (searchResult.labelInLanguage != null) {
            labelMap['label_language'] = searchResult.labelInLanguage;
          }
          return labelMap;
        }).toList());
      }

      return results;
    }).catchError((error, stackTrace) {
      FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: false);
    });
  }

  String _adjustLabel(String label) {
    if (label.indexOf(' (') >= 0) {
      return label.substring(0, label.indexOf(' ('));
    }
    return label;
  }

  @override
  void initState() {
    super.initState();
    _firebaseAnalytics = FirebaseAnalytics();
    _key = new GlobalKey<ScaffoldState>();
    _genericEntitiesF = rootReference.child(firebaseSettingsGenericEntities).once().then((snapshot) {
      return snapshot?.value ?? [];
    });
    _engineF = rootReference.child(firebaseSettingsEngine).once().then((snapshot) {
      return snapshot?.value ?? "";
    });
    imageLabeler = FirebaseVision.instance.cloudImageLabeler();
  }

  @override
  void dispose() {
    imageLabeler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var self = this;
    double maxSize = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).product_photo_search_title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: () {
              _getImage(_key, ImageSource.camera, maxSize);
            },
          ),
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: () {
              _getImage(_key, ImageSource.gallery, maxSize);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            child: Container(
              padding: EdgeInsets.all(5.0),
              width: maxSize,
              height: maxSize,
              child: _image == null
                  ? Center(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        GestureDetector(
                          child: Icon(Icons.add_a_photo, color: Theme.of(context).buttonColor, size: 80.0),
                          onTap: () {
                            _getImage(_key, ImageSource.camera, maxSize);
                          },
                        ),
                        SizedBox(width: 80.0),
                        GestureDetector(
                          child: Icon(Icons.add_photo_alternate, color: Theme.of(context).buttonColor, size: 80.0),
                          onTap: () {
                            _getImage(_key, ImageSource.gallery, maxSize);
                          },
                        )
                      ]),
                    )
                  : Image.file(_image, fit: BoxFit.cover, width: maxSize, height: maxSize),
            ),
          ),
          Card(
              child: Padding(
            padding: EdgeInsets.all(10.0),
            child: _image == null
                ? Text(
                    S.of(context).photo_search_note,
                    style: TextStyle(fontSize: 18.0),
                  )
                : FutureBuilder<List<SearchResult>>(
                    future: _searchResultF,
                    builder: (BuildContext context, AsyncSnapshot<List<SearchResult>> results) {
                      switch (results.connectionState) {
                        case ConnectionState.done:
                          if (results.data == null || results.data.isEmpty) {
                            return Text(
                              S.of(context).photo_search_empty,
                              style: TextStyle(fontSize: 18.0),
                            );
                          } else {
                            return Column(
                              children: results.data.map((result) {
                                if (result.count != null && result.count > 0) {
                                  return ListTile(
                                    leading: CircleAvatar(child:Text(NumberFormat.percentPattern().format(result.confidence), textAlign: TextAlign.center,),),
                                    title: result.labelInLanguage.isNotEmpty ? Text(result.labelInLanguage) : Text(result.labelLatin),
                                    subtitle: result.labelInLanguage.isNotEmpty ? Text(result.labelLatin) : null,
                                    trailing: Text(result.count.toString()),
                                    onTap: () {
                                      if (result.path.contains('/')) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  PlantList(widget.onChangeLanguage, {}, '',  rootReference.child(result.path))),
                                        );
                                      } else {
                                        goToDetail(self, context, widget.myLocale, result.path, widget.onChangeLanguage, {});
                                      }
                                    },
                                  );
                                } else {
                                  return ListTile(
                                    leading: CircleAvatar(child:Text(NumberFormat.percentPattern().format(result.confidence)), backgroundColor: Colors.white,),
                                    title: Text(result.labelLatin.toLowerCase()),
                                  );
                                }
                              }).toList(),
                            );
                          }
                          break;
                        default:
                          return Center(
                            child: const CircularProgressIndicator(),
                          );
                      }
                    }),
          )),
        ],
      ),
    );
  }
}
