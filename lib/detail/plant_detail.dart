import 'dart:async';
import 'dart:convert';

import 'package:abherbs_flutter/detail/plant_detail_gallery.dart';
import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/detail/plant_detail_taxonomy.dart';
import 'package:abherbs_flutter/dialogs.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/entity/translations.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/offline.dart';
import 'package:abherbs_flutter/purchases.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:http/http.dart' as http;

class PlantDetail extends StatefulWidget {
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, String> filter;
  final Plant plant;
  PlantDetail(this.myLocale, this.onChangeLanguage, this.onBuyProduct, this.filter, this.plant);

  @override
  _PlantDetailState createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  StreamSubscription<FirebaseUser> _listener;
  FirebaseUser _currentUser;
  FirebaseAnalytics _firebaseAnalytics;
  Future<PlantTranslation> _plantTranslationF;
  int _currentIndex;
  bool _isOriginal;
  GlobalKey<ScaffoldState> _key;

  onChangeTranslation(bool isOriginal) {
    setState(() {
      _isOriginal = isOriginal;
      _plantTranslationF = _getTranslation();
    });
  }

  Future<PlantTranslation> _getTranslation() {
    return translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(widget.plant.name).once().then((DataSnapshot snapshot) {
      var plantTranslation = snapshot.value == null ? PlantTranslation() : PlantTranslation.fromJson(snapshot.value);
      if (plantTranslation.isTranslated()) {
        return plantTranslation;
      } else {
        plantTranslation.isTranslatedWithGT = true;
        if (_isOriginal) {
          return translationsReference
              .child(widget.myLocale.languageCode == languageCzech ? languageSlovak : languageEnglish)
              .child(widget.plant.name)
              .once()
              .then((DataSnapshot snapshot) {
            var plantTranslationOriginal = PlantTranslation.fromJson(snapshot.value);
            return plantTranslation.mergeDataWith(plantTranslationOriginal);
          });
        } else {
          return translationsReference
              .child(getLanguageCode(widget.myLocale.languageCode) + languageGTSuffix)
              .child(widget.plant.name)
              .once()
              .then((DataSnapshot snapshot) {
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
              return translationsReference
                  .child(widget.myLocale.languageCode == languageCzech ? languageSlovak : languageEnglish)
                  .child(widget.plant.name)
                  .once()
                  .then((DataSnapshot snapshot) {
                var plantTranslationOriginal = PlantTranslation.fromJson(snapshot.value);
                var uri = googleTranslateEndpoint + '?key=' + translateAPIKey;
                uri += '&source=' + (languageCzech == widget.myLocale.languageCode ? languageSlovak : languageEnglish);
                uri += '&target=' + getLanguageCode(widget.myLocale.languageCode);
                for (var text in plantTranslation.getTextsToTranslate(plantTranslationOriginal)) {
                  uri += '&q=' + text;
                }
                return http.get(uri).then((response) {
                  if (response.statusCode == 200) {
                    Translations translations = Translations.fromJson(json.decode(response.body));
                    PlantTranslation onlyGoogleTranslation =
                        plantTranslation.fillTranslations(translations.translatedTexts, plantTranslationOriginal);
                    translationsReference
                        .child(getLanguageCode(widget.myLocale.languageCode) + languageGTSuffix)
                        .child(widget.plant.name)
                        .set(onlyGoogleTranslation.toJson());
                    return plantTranslation;
                  } else {
                    return plantTranslation.mergeWith(plantTranslationOriginal);
                  }
                });
              });
            }
          });
        }
      }
    });
  }

  Future<void> _logSelectContentEvent(String contentId) async {
    await _firebaseAnalytics.logSelectContent(
      contentType: 'plant',
      itemId: contentId,
    );
  }

  Widget _getBody(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return getGallery(context, widget.plant);
      case 1:
        return getInfo(context, widget.myLocale, _isOriginal, widget.plant, _plantTranslationF, this.onChangeTranslation, _key);
      case 2:
        return getTaxonomy(context, widget.myLocale, widget.plant, _plantTranslationF);
    }
    return null;
  }

  _onAuthStateChanged(FirebaseUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _checkCurrentUser() async {
    _currentUser = await Auth.getCurrentUser();
    _listener = Auth.subscribe(_onAuthStateChanged);
  }

  @override
  void initState() {
    super.initState();
    Offline.setKeepSynced(3, true);
    _checkCurrentUser();
    _firebaseAnalytics = FirebaseAnalytics();

    _plantTranslationF = _getTranslation();

    _currentIndex = 0;
    _isOriginal = false;
    _key = new GlobalKey<ScaffoldState>();

    _logSelectContentEvent(widget.plant.name);
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var items = <BottomNavigationBarItem>[];
    items.add(BottomNavigationBarItem(icon: Icon(Icons.photo_library), title: Text(S.of(context).plant_gallery)));
    items.add(BottomNavigationBarItem(icon: Icon(Icons.info), title: Text(S.of(context).plant_info)));
    items.add(BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), title: Text(S.of(context).plant_taxonomy)));
    if (Purchases.isObservations()) {
      items.add(BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye), title: Text(S.of(context).observations)));
    }

    return Scaffold(
      key: _key,
      appBar: AppBar(
          title: GestureDetector(
        child: Text(widget.plant.name),
        onLongPress: () {
          Clipboard.setData(new ClipboardData(text: widget.plant.name));
          _key.currentState.showSnackBar(SnackBar(
            content: Text(S.of(context).snack_copy),
          ));
        },
      )),
      drawer: AppDrawer(_currentUser, widget.onChangeLanguage, widget.onBuyProduct, widget.filter, null),
      body: _getBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: items,
        type: BottomNavigationBarType.fixed,
        fixedColor: Colors.blue,
        onTap: (index) {
          if (index == 3 && _currentUser == null) {
            observationDialog(context, _key);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
