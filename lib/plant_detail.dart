import 'package:abherbs_flutter/constants.dart';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:firebase_database/firebase_database.dart';

final plantsReference = FirebaseDatabase.instance.reference().child(firebasePlants);
final translationsReference = FirebaseDatabase.instance.reference().child(firebaseTranslations);

class PlantDetail extends StatefulWidget {
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final String plantName;
  PlantDetail(this.myLocale, this.onChangeLanguage, this.filter, this.plantName);

  @override
  _PlantDetailState createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  Future<Plant> _plantF;
  Future<PlantTranslation> _plantTranslationF;

  @override
  void initState() {
    super.initState();

    Ads.hideBannerAd();

    _plantF = plantsReference.child(widget.plantName).once().then((DataSnapshot snapshot) {
      return Plant.fromJson(snapshot.key, snapshot.value);
    });

    _plantTranslationF = translationsReference.child(widget.myLocale.languageCode).child(widget.plantName).once().then((DataSnapshot snapshot) {
      var plantTranslation = PlantTranslation.fromJson(snapshot.value);
      if (plantTranslation.isTranslated)
        return plantTranslation;
      else
        return translationsReference
            .child(widget.myLocale.languageCode + languageGTSuffix)
            .child(widget.plantName)
            .once()
            .then((DataSnapshot snapshot) {
          var plantTranslationGT = PlantTranslation.fromJson(snapshot.value);
          plantTranslationGT.copyFrom(plantTranslation);
          if (plantTranslationGT.label == null) {
            plantTranslationGT.label = widget.plantName;
          }
          if (plantTranslationGT.isTranslated)
            return plantTranslationGT;
          else
            return translationsReference.child(languageEnglish).child(widget.plantName).once().then((DataSnapshot snapshot) {
              var plantTranslationEn = PlantTranslation.fromJson(snapshot.value);

              return plantTranslationGT;
            });
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantName),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, widget.filter, null),
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(5.0),
        children: [
          Card(
            child: Container(
              padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: FutureBuilder<PlantTranslation>(
                future: _plantTranslationF,
                builder: (BuildContext context, AsyncSnapshot<PlantTranslation> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Column( mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator()]);
                    default:
                      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(
                          snapshot.data.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          snapshot.data.names == null ? '' : snapshot.data.names.take(3).join(', '),
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 14.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ]);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.info), title: Text(S.of(context).filter_habitat)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), title: Text(S.of(context).filter_petal)),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), title: Text(S.of(context).filter_distribution)),
        ],
        fixedColor: Colors.blue,
        onTap: (index) {},
      ),
    );
  }
}
