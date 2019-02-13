import 'dart:async';
import 'dart:convert';

import 'package:abherbs_flutter/detail/plant_detail_gallery.dart';
import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/detail/plant_detail_taxonomy.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/entity/translations.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/offline.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:http/http.dart' as http;

final plantsReference = FirebaseDatabase.instance.reference().child(firebasePlants);
final translationsReference = FirebaseDatabase.instance.reference().child(firebaseTranslations);

class PlantDetail extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, String> filter;
  final String plantName;
  PlantDetail(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct, this.filter, this.plantName);

  @override
  _PlantDetailState createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  FirebaseAnalytics _firebaseAnalytics;
  Future<Plant> _plantF;
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
    return translationsReference.child(getLanguageCode(widget.myLocale.languageCode)).child(widget.plantName).once().then((DataSnapshot snapshot) {
      var plantTranslation = snapshot.value == null ? PlantTranslation() : PlantTranslation.fromJson(snapshot.value);
      if (plantTranslation.isTranslated()) {
        return plantTranslation;
      } else {
        plantTranslation.isTranslatedWithGT = true;
        if (_isOriginal) {
          return translationsReference
              .child(widget.myLocale.languageCode == languageCzech ? languageSlovak : languageEnglish)
              .child(widget.plantName)
              .once()
              .then((DataSnapshot snapshot) {
            var plantTranslationOriginal = PlantTranslation.fromJson(snapshot.value);
            return plantTranslation.mergeDataWith(plantTranslationOriginal);
          });
        } else {
          return translationsReference
              .child(getLanguageCode(widget.myLocale.languageCode) + languageGTSuffix)
              .child(widget.plantName)
              .once()
              .then((DataSnapshot snapshot) {
            var plantTranslationGT = PlantTranslation.copy(plantTranslation);
            if (snapshot.value != null) {
              plantTranslationGT = PlantTranslation.fromJson(snapshot.value);
              plantTranslationGT.mergeWith(plantTranslation);
            }
            if (plantTranslationGT.label == null) {
              plantTranslationGT.label = widget.plantName;
            }
            if (plantTranslationGT.isTranslated()) {
              plantTranslationGT.isTranslatedWithGT = true;
              return plantTranslationGT;
            } else {
              return translationsReference
                  .child(widget.myLocale.languageCode == languageCzech ? languageSlovak : languageEnglish)
                  .child(widget.plantName)
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
                        .child(widget.plantName)
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

  @override
  void initState() {
    super.initState();
    Offline.setKeepSynced3(true);
    _firebaseAnalytics = FirebaseAnalytics();

    _plantF = plantsReference.child(widget.plantName).once().then((DataSnapshot snapshot) {
      return Plant.fromJson(snapshot.key, snapshot.value);
    });
    _plantTranslationF = _getTranslation();

    _currentIndex = 0;
    _isOriginal = false;
    _key = new GlobalKey<ScaffoldState>();

    _logSelectContentEvent(widget.plantName);
  }

  Widget _getBody(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return getGallery(context, _plantF);
      case 1:
        return getInfo(context, widget.myLocale, _isOriginal, _plantF, _plantTranslationF, this.onChangeTranslation, _key);
      case 2:
        return getTaxonomy(context, widget.myLocale, _plantF, _plantTranslationF);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
          title: GestureDetector(
        child: Text(widget.plantName),
        onLongPress: () {
          Clipboard.setData(new ClipboardData(text: widget.plantName));
          _key.currentState.showSnackBar(SnackBar(
            content: Text(S.of(context).snack_copy),
          ));
        },
      )),
      drawer: AppDrawer(widget.currentUser, widget.onChangeLanguage, widget.onBuyProduct, widget.filter, null),
      body: _getBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), title: Text(S.of(context).plant_gallery)),
          BottomNavigationBarItem(icon: Icon(Icons.info), title: Text(S.of(context).plant_info)),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), title: Text(S.of(context).plant_taxonomy)),
        ],
        fixedColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
