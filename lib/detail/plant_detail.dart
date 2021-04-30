import 'dart:async';
import 'dart:convert';

import 'package:abherbs_flutter/detail/plant_detail_gallery.dart';
import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/detail/plant_detail_taxonomy.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/entity/translations.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/observations/observation_edit.dart';
import 'package:abherbs_flutter/observations/observation_logs.dart';
import 'package:abherbs_flutter/observations/observations_plant.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import 'package:youtube_plyr_iframe/youtube_plyr_iframe.dart';

import '../main.dart';

const int galleryIndex = 0;
const int infoIndex = 1;
const int taxonomyIndex = 2;
const int observationIndex = 3;

class PlantDetail extends StatefulWidget {
  final Locale myLocale;
  final Map<String, String> filter;
  final Plant plant;

  PlantDetail(this.myLocale, this.filter, this.plant);

  @override
  _PlantDetailState createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics();
  StreamSubscription<firebase_auth.User> _listener;
  AppUser _currentUser;
  Future<PlantTranslation> _plantTranslationF;
  Future<bool> _isFavoriteF;
  int _currentIndex;
  GlobalKey<ScaffoldState> _key;
  bool _isPublic;
  double _fontSize;
  bool _showAd;
  BannerAd _adGallery;
  BannerAd _adInfo;
  BannerAd _adTaxonomy;

  onChangeFontSize() {
    setState(() {
      if (_fontSize == maxFontSize) {
        _fontSize = defaultFontSize;
      } else {
        _fontSize += 2;
      }
      Prefs.setDouble(keyFontSize, _fontSize);
    });
  }

  onShare() {
    Share.share(Uri.encodeFull('https://whatsthatflower.com/?plant=' + widget.plant.name + '&lang=' + widget.myLocale.languageCode), subject: widget.plant.name);
    _logShareEvent(widget.plant.name);
  }

  Future<PlantTranslation> _getTranslation() {
    return translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(widget.plant.name).once().then((DataSnapshot snapshot) {
      var plantTranslation = snapshot.value == null ? PlantTranslation() : PlantTranslation.fromJson(snapshot.value);
      if (plantTranslation.isTranslated()) {
        return plantTranslation;
      } else {
        plantTranslation.isTranslatedWithGT = true;
        return translationsReference.child(getLanguageCode(widget.myLocale.languageCode) + languageGTSuffix).child(widget.plant.name).once().then((DataSnapshot snapshot) {
          var plantTranslationGT = PlantTranslation.copy(plantTranslation);
          if (snapshot.value != null) {
            plantTranslationGT = PlantTranslation.fromJson(snapshot.value);
            plantTranslationGT.mergeWith(plantTranslation);
          }
          if (plantTranslationGT.label == null) {
            plantTranslationGT.label = widget.plant.name;
          }
          if (plantTranslationGT.isTranslated()) {
            plantTranslationGT.isTranslatedWithGT = true;
            return plantTranslationGT;
          } else {
            return translationsReference.child(widget.myLocale.languageCode == languageCzech ? languageSlovak : languageEnglish).child(widget.plant.name).once().then((DataSnapshot snapshot) {
              var plantTranslationOriginal = PlantTranslation.fromJson(snapshot.value);
              var uri = googleTranslateEndpoint + '?key=' + translateAPIKey;
              uri += '&source=' + (languageCzech == widget.myLocale.languageCode ? languageSlovak : languageEnglish);
              uri += '&target=' + getLanguageCode(widget.myLocale.languageCode);
              for (var text in plantTranslation.getTextsToTranslate(plantTranslationOriginal)) {
                uri += '&q=' + text;
              }
              return http.get(Uri.parse(uri)).then((response) {
                if (response.statusCode == 200) {
                  Translations translations = Translations.fromJson(json.decode(response.body));
                  PlantTranslation onlyGoogleTranslation = plantTranslation.fillTranslations(translations.translatedTexts, plantTranslationOriginal);
                  translationsReference.child(getLanguageCode(widget.myLocale.languageCode) + languageGTSuffix).child(widget.plant.name).set(onlyGoogleTranslation.toJson());
                  return plantTranslation;
                } else {
                  return plantTranslation.mergeWith(plantTranslationOriginal);
                }
              });
            });
          }
        });
      }
    });
  }

  Future<bool> _setFavorite() {
    return Future<bool>(() {
      if (_currentUser != null) {
        return usersReference.child(_currentUser.firebaseUser.uid).child(firebaseAttributeFavorite).child(widget.plant.id.toString()).once().then((snapshot) {
          return snapshot.value != null && snapshot.value == 1;
        });
      }
      return false;
    });
  }

  Future<void> _logSelectContentEvent(String contentId) async {
    await _firebaseAnalytics.logSelectContent(
      contentType: 'plant',
      itemId: contentId,
    );
  }

  Future<void> _logShareEvent(String contentId) async {
    await _firebaseAnalytics.logSelectContent(
      contentType: 'share',
      itemId: contentId,
    );
  }

  Widget _getBody(BuildContext context) {
    switch (_currentIndex) {
      case galleryIndex:
        return getGallery(context, widget.plant, _showAd, _adGallery);
      case infoIndex:
        return getInfo(context, widget.myLocale, widget.plant, _plantTranslationF, _fontSize, _key, _showAd, _adInfo);
      case taxonomyIndex:
        return getTaxonomy(context, widget.myLocale, widget.plant, _plantTranslationF, _fontSize, _showAd, _adTaxonomy);
      case observationIndex:
        return ObservationsPlant(_currentUser, Localizations.localeOf(context), _isPublic, widget.plant.name, _key);
    }
    return null;
  }

  void _setIsPublic(bool isPublic) {
    if (Purchases.isSubscribed()) {
      setState(() {
        _isPublic = isPublic;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ObservationLogs(_currentUser, Localizations.localeOf(context), 0), settings: RouteSettings(name: 'ObservationLogs')),
      );
    }
  }

  _onAuthStateChanged(firebase_auth.User user) {
    setState(() {
      _currentUser = Auth.getAppUser();
    });
  }

  void _checkCurrentUser() {
    _currentUser = Auth.getAppUser();
    _listener = Auth.subscribe(_onAuthStateChanged);
    _isFavoriteF = _setFavorite();
  }

  @override
  void initState() {
    super.initState();
    Offline.setKeepSynced(3, true);
    _checkCurrentUser();

    _showAd = !Purchases.isNoAds();

    if (_showAd) {
      _adGallery = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.largeBanner,
        request: AdRequest(),
        listener: AdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
          onAdClosed: (Ad ad) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
        ),
      );
      _adGallery.load();

      _adInfo = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.largeBanner,
        request: AdRequest(),
        listener: AdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
          onAdClosed: (Ad ad) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
        ),
      );
      _adInfo.load();

      _adTaxonomy = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.largeBanner,
        request: AdRequest(),
        listener: AdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
          onAdClosed: (Ad ad) {
            setState(() {
              _showAd = false;
            });
            ad.dispose();
          },
        ),
      );
      _adTaxonomy.load();
    }

    _plantTranslationF = _getTranslation();

    _currentIndex = 0;
    _key = new GlobalKey<ScaffoldState>();
    _isPublic = false;
    _fontSize = Prefs.getDouble(keyFontSize, defaultFontSize);

    _logSelectContentEvent(widget.plant.name);
  }

  @override
  void dispose() {
    _listener.cancel();
    _adGallery.dispose();
    _adInfo.dispose();
    _adTaxonomy.dispose();
    for (YoutubePlayerController controller in getYoutubeControllers()) {
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
    var items = <BottomNavigationBarItem>[];
    items.add(BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: S.of(context).plant_gallery));
    items.add(BottomNavigationBarItem(icon: Icon(Icons.info), label: S.of(context).plant_info));
    items.add(BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), label: S.of(context).plant_taxonomy));
    if (Purchases.isObservations()) {
      items.add(BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye), label: S.of(context).observations));
    }

    return Scaffold(
      key: _key,
      appBar: _currentIndex == observationIndex
          ? AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      child: Text(widget.plant.name),
                      onLongPress: () {
                        Clipboard.setData(new ClipboardData(text: widget.plant.name));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(S.of(context).snack_copy),
                        ));
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        Switch(
                          value: _isPublic,
                          activeColor: Colors.white,
                          inactiveThumbColor: Colors.white,
                          onChanged: (bool value) {
                            _setIsPublic(value);
                          },
                        ),
                        Icon(Icons.people),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _currentIndex == infoIndex || _currentIndex == taxonomyIndex
              ? AppBar(
                  title: GestureDetector(
                    child: Text(widget.plant.name),
                    onLongPress: () {
                      Clipboard.setData(new ClipboardData(text: widget.plant.name));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(S.of(context).snack_copy),
                      ));
                    },
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.format_size),
                      onPressed: () {
                        onChangeFontSize();
                      },
                    ),
                  ],
                )
              : AppBar(
                  title: GestureDetector(
                    child: Text(widget.plant.name),
                    onLongPress: () {
                      Clipboard.setData(new ClipboardData(text: widget.plant.name));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(S.of(context).snack_copy),
                      ));
                    },
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        onShare();
                      },
                    ),
                  ],
                ),
      drawer: AppDrawer(_currentUser, widget.filter, null),
      body: _getBody(context),
      floatingActionButton: Container(
        height: 70.0,
        width: 70.0,
        child: FittedBox(
          fit: BoxFit.fill,
          child: FutureBuilder<bool>(
              future: _isFavoriteF,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                return FloatingActionButton(
                  onPressed: () {
                    if (_currentIndex == observationIndex) {
                      var observation = Observation(widget.plant.name);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ObservationEdit(_currentUser, widget.myLocale, observation), settings: RouteSettings(name: 'ObservationEdit')),
                      ).then((value) {
                        if (value != null && value && _key.currentState != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(S.of(context).observation_saved),
                          ));
                        }
                        setState(() {});
                      });
                    } else {
                      if (_currentUser != null) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          usersReference.child(_currentUser.firebaseUser.uid).child(firebaseAttributeFavorite).child(widget.plant.id.toString()).set(snapshot.data ? null : 1).then((value) {
                            if (mounted) {
                              setState(() {
                                _isFavoriteF = _setFavorite();
                              });
                            }
                          });
                        }
                      } else {
                        favoriteDialog(context, _key);
                      }
                    }
                  },
                  child: _currentIndex == observationIndex
                      ? Icon(Icons.add)
                      : snapshot.connectionState == ConnectionState.done && snapshot.data != null && snapshot.data
                          ? Icon(Icons.favorite)
                          : Icon(Icons.favorite_border),
                );
              }),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: items,
        type: BottomNavigationBarType.fixed,
        fixedColor: Colors.blue,
        onTap: (index) {
          Connectivity().checkConnectivity().then((result) {
            if (index == observationIndex) {
              if (result == ConnectivityResult.none) {
                infoDialog(context, S.of(context).no_connection_title, S.of(context).no_connection_content);
              } else if (_currentUser == null) {
                observationDialog(context, _key);
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          });
        },
      ),
    );
  }
}
