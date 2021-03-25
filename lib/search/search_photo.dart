import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/signin/sign_in.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../main.dart';

class SearchResult {
  double confidence;
  int count;
  String entityId;
  String labelInLanguage;
  String labelLatin;
  String path;
  Map<String, dynamic> plantDetails;
  List<dynamic> similarImages;
  String commonName;
}

class SearchPhoto extends StatefulWidget {
  final AppUser currentUser;
  final Locale myLocale;
  SearchPhoto(this.currentUser, this.myLocale);

  @override
  _SearchPhotoState createState() => _SearchPhotoState();
}

class _SearchPhotoState extends State<SearchPhoto> {
  final ImagePicker _picker = ImagePicker();

  FirebaseAnalytics _firebaseAnalytics;
  GlobalKey<ScaffoldState> _key;
  File _image;
  Future<List<SearchResult>> _searchResultF;
  Future<List<dynamic>> _genericEntitiesF;
  Future<String> _engineF;
  ImageLabeler imageLabeler;

  AdmobReward _rewardAd;
  bool _isRewardLoading;

  void handleEvent(AdmobAdEvent event, Map<String, dynamic> args, String adType) async {
    switch (event) {
      case AdmobAdEvent.loaded:
        if (adType == 'Reward') {
          _isRewardLoading = false;
        }
        break;
      case AdmobAdEvent.failedToLoad:
        if (adType == 'Reward') {
          _isRewardLoading = true;
          _rewardAd.load();
        }
        break;
      case AdmobAdEvent.clicked:
        break;
      case AdmobAdEvent.impression:
        break;
      case AdmobAdEvent.opened:
        break;
      case AdmobAdEvent.leftApplication:
        break;
      case AdmobAdEvent.closed:
        if (adType == 'Reward') {
          _isRewardLoading = true;
          _rewardAd.load();
        }
        break;
      case AdmobAdEvent.completed:
        break;
      case AdmobAdEvent.rewarded:
        await Auth.changeCredits(1, "1");
        setState(() {});
        break;
      case AdmobAdEvent.started:
        break;
    }
  }

  Future<void> _logPhotoSearchEvent() async {
    await _firebaseAnalytics.logEvent(name: 'search_photo');
  }

  Future<void> _getImage(GlobalKey<ScaffoldState> _key, ImageSource source, double maxSize) async {
    if (Purchases.isPhotoSearch() || widget.currentUser.credits > 0) {
      setState(() {
        _image = null;
        _searchResultF = Future<List<SearchResult>>(() {
          return null;
        });
      });
      var image = await _picker.getImage(source: source, maxWidth: maxSize);
      if (image != null) {
        _logPhotoSearchEvent();
        var engine = await _engineF;
        setState(() {
          _image = File(image.path);
          if (engine == plantIdEngine) {
            _searchResultF = _getSearchResultPlantId(_image);
          } else {
            _searchResultF = _getSearchResult(_image);
          }
        });
      }
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

    return http.post(Uri.parse(plantIdEndpoint), headers: headers, body: msg).then((response) async {
      var results = <SearchResult>[];
      if (response.statusCode == 200) {
        if (widget.currentUser != null && !Purchases.isPhotoSearch()) {
            await Auth.changeCredits(-1, "search by photo");
            if (mounted) {
              setState(() {});
            }
        }
        Map responseBody = json.decode(response.body);
        for (var suggestion in responseBody['suggestions']) {
          if (suggestion == null) {
            continue;
          }
          String plantName = suggestion['plant_details']['scientific_name'];
          results.add(await rootReference.child(firebaseSearchPhoto + '/' + plantName.toLowerCase().replaceAll('.', '')).once().then((snapshot) {
            var result = SearchResult();
            result.labelLatin = plantName;
            result.entityId = suggestion['id'].toString();
            result.confidence = suggestion['probability'];
            result.plantDetails = suggestion['plant_details'];
            result.similarImages = suggestion['similar_images'];
            result.commonName = suggestion['plant_details']['common_names'] != null ? suggestion['plant_details']['common_names'][0] : "";
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
                return translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(result.labelLatin).child(firebaseAttributeLabel).once().then((snapshot) {
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
                return translationsTaxonomyReference.child(widget.myLocale.languageCode).child(result.labelLatin).once().then((snapshot) {
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
          userId = widget.currentUser.firebaseUser.uid;
        }

        rootReference.child(firebaseUsersPhotoSearch).child(widget.myLocale.languageCode).child(userId).child(DateTime.now().millisecondsSinceEpoch.toString())
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
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
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
              return translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(result.labelLatin).child(firebaseAttributeLabel).once().then((snapshot) {
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
              return translationsTaxonomyReference.child(widget.myLocale.languageCode).child(result.labelLatin).once().then((snapshot) {
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
          userId = widget.currentUser.firebaseUser.uid;
        }
        rootReference.child(firebaseUsersPhotoSearch).child(userId).child(DateTime.now().millisecondsSinceEpoch.toString()).set(results.map((searchResult) {
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
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
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
    _isRewardLoading = true;
    _rewardAd = AdmobReward(
      adUnitId: getRewardAdUnitId(),
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        handleEvent(event, args, 'Reward');
      },
    );
    _rewardAd.load();
    imageLabeler = FirebaseVision.instance.cloudImageLabeler();
  }

  @override
  void dispose() {
    imageLabeler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
    var self = this;
    double maxSize = MediaQuery.of(context).size.width;
    TextStyle feedbackTextStyle = TextStyle(
      fontSize: 18.0,
    );
    TextStyle creditsTextStyle = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );

    var _widgets = <Widget>[];
    _widgets.add(Card(
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
    ));

    if (!Purchases.isPhotoSearch()) {
      if (widget.currentUser == null) {
        _widgets.add(Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                S.of(context).credit_login,
                style: feedbackTextStyle,
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen(), settings: RouteSettings(name: 'SignIn')),
                  ).then((result) {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
                child: Text(S.of(context).auth_sign_in),
              ),
            ]),
          ),
        ));
      } else {
        _widgets.add(Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                S.of(context).credit_message,
                style: feedbackTextStyle,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(S.of(context).credit_count, style: creditsTextStyle,),
                    Text(widget.currentUser.credits.toString(), style: creditsTextStyle,),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_isRewardLoading) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(S.of(context).snack_loading_ad),
                      duration: Duration(milliseconds: 1500),
                    ));
                  } else {
                    _rewardAd.show();
                  }
                },
                child: Text(S.of(context).credit_ads_video),
              ),
            ]),
          ),
        ));
      }
    }

    if (_image == null) {
      _widgets.add(Card(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              S.of(context).photo_search_note,
              style: TextStyle(fontSize: 18.0),
            ))));
    } else {
      _widgets.add(Card(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: FutureBuilder<List<SearchResult>>(
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
                            if (result.path != null && result.path.isNotEmpty) {
                              return Container(
                                  decoration: BoxDecoration(color: Colors.lightBlueAccent),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                          NumberFormat.percentPattern().format(result.confidence)),
                                      backgroundColor: Colors.white,
                                    ),
                                    title: result.labelInLanguage.isNotEmpty ? Text(result.labelInLanguage) : Text(result.labelLatin),
                                    subtitle: result.labelInLanguage.isNotEmpty ? Text(result.labelLatin) : null,
                                    trailing: Text(result.count.toString()),
                                    onTap: () {
                                      if (result.path.contains('/')) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PlantList({}, '', rootReference.child(result.path)), settings: RouteSettings(name: 'PlantList')),
                                        );
                                      } else {
                                        goToDetail(self, context, widget.myLocale, result.path, {});
                                      }
                                    },
                                    onLongPress: () {
                                      Clipboard.setData(new ClipboardData(text: result.labelLatin));
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(S.of(context).snack_copy),
                                      ));
                                    },
                                  ));
                            } else {
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(NumberFormat.percentPattern().format(result.confidence)),
                                  backgroundColor: Colors.white,
                                ),
                                title: result.commonName != null && result.commonName.isNotEmpty ? Text(result.commonName) : Text(result.labelLatin),
                                subtitle: result.commonName != null && result.commonName.isNotEmpty ? Text(result.labelLatin) : null,
                                onLongPress: () {
                                  Clipboard.setData(new ClipboardData(text: result.labelLatin));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(S.of(context).snack_copy),
                                  ));
                                },
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
          )));
    }

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
        children: _widgets,
      ),
    );
  }
}
